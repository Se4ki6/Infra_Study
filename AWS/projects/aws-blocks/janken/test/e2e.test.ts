import { test } from 'node:test';
import assert from 'node:assert';
import { spawn, type ChildProcess } from 'node:child_process';
import { setTimeout } from 'node:timers/promises';
import { installCookieJar, isServerRunning } from '@aws-blocks/blocks/utils';
import type { api as apiType, authApi as authApiType } from 'aws-blocks';

installCookieJar();

let server: ChildProcess | null = null;
let api: typeof apiType;
let authApi: typeof authApiType;

test.before(async () => {
  if (!await isServerRunning()) {
    server = spawn('npm', ['run', 'dev:server'], {
      cwd: process.cwd(),
      stdio: ['ignore', 'pipe', 'pipe'],
      detached: true,
      env: { ...process.env, NODE_OPTIONS: '' },
    });
    server.unref();
    await setTimeout(2000);
  }

  const mod = await import('aws-blocks');
  api = mod.api;
  authApi = mod.authApi;

  // Wait for server to be ready
  for (let i = 0; i < 60; i++) {
    try { await api.getRanking(1); return; } catch {
      await setTimeout(1000);
    }
  }
  throw new Error('Server not ready');
});

test.after(() => {
  if (server?.pid) {
    try { process.kill(-server.pid, 'SIGTERM'); } catch {}
  }
});

test('playRound requires auth', async () => {
  await assert.rejects(() => api.playRound('rock'));
});

test('full game: sign up, play 10 rounds, land on ranking', async () => {
  const username = `tester_${Date.now()}`;
  const password = 'password123';

  // サインアップ（codeDelivery 未設定なので即時確定＋セッション付与）
  await authApi.setAuthState({ action: 'signUp', username, password });

  // 念のためサインインしてセッションを確実にする
  await authApi.setAuthState({ action: 'signIn', username, password });

  const start = await api.startGame();
  assert.strictEqual(start.round, 0);
  assert.strictEqual(start.totalRounds, 10);

  let last;
  for (let i = 1; i <= 10; i++) {
    last = await api.playRound('rock');
    assert.strictEqual(last.round, i);
    assert.ok(['win', 'lose', 'draw'].includes(last.outcome));
    assert.ok(last.wins >= 0 && last.wins <= i);
  }
  assert.strictEqual(last!.finished, true);

  // 11手目はセッションが消えているので弾かれる
  await assert.rejects(() => api.playRound('rock'));

  // ランキングに自分の結果が載っている
  const ranking = await api.getRanking(50);
  const mine = ranking.find((r) => r.username === username);
  assert.ok(mine, 'ranking should include the finished game');
  assert.strictEqual(mine!.wins, last!.wins);
});
