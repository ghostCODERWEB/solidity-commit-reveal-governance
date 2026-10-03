// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {SuiteBase, AssetFlow} from "./SuiteBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Commit-reveal token voting
/// @notice Token-escrowed commit/reveal proposals with quorum, immutable phase deadlines and refundable voting deposits.
/// @dev Reference implementation; independent audit required before production.

contract CommitRevealVoting is SuiteBase {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;
    uint256 public nextProposal;
    uint256 public escrowed;
    struct Proposal {
        uint64 commitEnd;
        uint64 revealEnd;
        uint256 quorum;
        uint256 yes;
        uint256 no;
        bool finalized;
        bool passed;
    }
    struct Ballot {
        bytes32 commitment;
        uint256 weight;
        bool revealed;
        bool withdrawn;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => Ballot)) public ballots;
    event Proposed(
        uint256 indexed id,
        uint64 commitEnd,
        uint64 revealEnd,
        uint256 quorum
    );
    event Committed(uint256 indexed id, address indexed voter, uint256 weight);
    event Revealed(
        uint256 indexed id,
        address indexed voter,
        bool support,
        uint256 weight
    );
    event Finalized(uint256 indexed id, bool passed);
    constructor(address asset, address admin) SuiteBase(admin) {
        require(asset.code.length > 0, "asset");
        token = IERC20(asset);
    }
    function propose(
        uint64 commitDuration,
        uint64 revealDuration,
        uint256 quorum
    ) external onlyOwner whenNotPaused returns (uint256 id) {
        require(
            commitDuration > 0 && revealDuration > 0 && quorum > 0,
            "phases"
        );
        id = ++nextProposal;
        uint64 first = uint64(block.timestamp) + commitDuration;
        proposals[id] = Proposal(
            first,
            first + revealDuration,
            quorum,
            0,
            0,
            false,
            false
        );
        emit Proposed(id, first, first + revealDuration, quorum);
    }
    function ballotHash(
        uint256 id,
        address voter,
        bool support,
        bytes32 salt
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    block.chainid,
                    address(this),
                    id,
                    voter,
                    support,
                    salt
                )
            );
    }
    function commit(
        uint256 id,
        bytes32 hash,
        uint256 weight
    ) external nonReentrant whenNotPaused {
        Proposal memory p = proposals[id];
        Ballot storage b = ballots[id][msg.sender];
        require(
            p.commitEnd > block.timestamp &&
                hash != bytes32(0) &&
                weight > 0 &&
                b.weight == 0,
            "commit"
        );
        AssetFlow.pullExact(token, msg.sender, weight);
        b.commitment = hash;
        b.weight = weight;
        escrowed += weight;
        emit Committed(id, msg.sender, weight);
    }
    function reveal(uint256 id, bool support, bytes32 salt) external {
        Proposal storage p = proposals[id];
        Ballot storage b = ballots[id][msg.sender];
        require(
            block.timestamp >= p.commitEnd &&
                block.timestamp < p.revealEnd &&
                !b.revealed &&
                b.weight > 0,
            "reveal phase"
        );
        require(
            b.commitment == ballotHash(id, msg.sender, support, salt),
            "commitment"
        );
        b.revealed = true;
        if (support) p.yes += b.weight;
        else p.no += b.weight;
        emit Revealed(id, msg.sender, support, b.weight);
    }
    function finalize(uint256 id) external {
        Proposal storage p = proposals[id];
        require(
            p.revealEnd > 0 && block.timestamp >= p.revealEnd && !p.finalized,
            "finalize"
        );
        p.finalized = true;
        p.passed = p.yes + p.no >= p.quorum && p.yes > p.no;
        emit Finalized(id, p.passed);
    }
    function withdraw(uint256 id) external nonReentrant {
        Proposal memory p = proposals[id];
        Ballot storage b = ballots[id][msg.sender];
        require(
            p.revealEnd > 0 &&
                block.timestamp >= p.revealEnd &&
                b.weight > 0 &&
                !b.withdrawn,
            "withdraw"
        );
        b.withdrawn = true;
        escrowed -= b.weight;
        token.safeTransfer(msg.sender, b.weight);
    }
}
