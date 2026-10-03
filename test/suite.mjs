export async function suite(h) {
  const token = await h.token();
  const c = await h.deploy("CommitRevealVoting", [
    token.target,
    h.addresses[0],
  ]);
  await h.tx(token.approve(c.target, 1000));
  await h.tx(c.propose(20, 20, 100));
  const salt = h.ethers.id("salt");
  const hash = await c.ballotHash(1, h.addresses[0], true, salt);
  await h.tx(c.commit(1, hash, 150));
  await h.test("early reveal rejected", () =>
    h.revert(() => c.reveal(1, true, salt)),
  );
  await h.test("duplicate commitment rejected", () =>
    h.revert(() => c.commit(1, hash, 1)),
  );
  await h.test("incorrect salt rejected", async () => {
    await h.mine(21);
    await h.revert(() => c.reveal(1, true, h.ethers.id("wrong")));
  });
  await h.test("valid reveal tallies stake", async () => {
    await h.tx(c.reveal(1, true, salt));
    h.eq((await c.proposals(1)).yes, 150n);
  });
  await h.test("finalization respects quorum", async () => {
    await h.mine(21);
    await h.tx(c.finalize(1));
    h.eq((await c.proposals(1)).passed, true);
  });
  await h.test("escrow refunds exactly once", async () => {
    await h.tx(c.withdraw(1));
    h.eq(await c.escrowed(), 0n);
    await h.revert(() => c.withdraw(1));
  });
}
