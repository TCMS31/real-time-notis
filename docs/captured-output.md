# Captured output

Sections 1, 3, 4, 5 and 7 were captured on 2026-11-09 from the Docker Compose
stack (the production image on Ruby 3.4.12 and Rails 8.1.4.1, PostgreSQL 16,
Redis 7, no Twilio credentials so the `log` adapter is active), published on
host port 18860 via `WEB_PORT`. The test suite ran in a `ruby:3.4.12`
container against PostgreSQL 16 with networking disabled. Sections 2 and 6
are older measurements, dated where they appear. Commands and responses are
copied verbatim.

## 1. The message allow-list

`POST /messages` accepts a catalogue *key*, never message text. Only keys
flagged `user_triggerable` are accepted; `welcome` is system-only. A signed-in
session sent each key in turn and then read the flash:

```
POST /users (sign up)  -> HTTP 303 http://127.0.0.1:18860/
POST /messages message_key='transaction_success' -> HTTP 302 http://127.0.0.1:18860/ (9 ms); flash: ['Send transaction success SMS queued for +14••••••671.']
POST /messages message_key='welcome' -> HTTP 302 http://127.0.0.1:18860/ (12 ms); flash: ['That message is not one you can send.']
POST /messages message_key='Call 1-900-PREMIUM to claim your prize' -> HTTP 302 http://127.0.0.1:18860/ (13 ms); flash: ['That message is not one you can send.']
```

Only the first request enqueued anything (`docker compose logs web`):

```
[ActiveJob] Enqueued SendSmsJob (Job ID: 35941177-5872-45c4-9644-48bb158012a7) to Async(default) with arguments: {user_id: 2, message_key: "transaction_success"}
[ActiveJob] [SendSmsJob] [35941177-...] [sms:log] to=+14••••••671 body="Hey Ada Lovelace, your transaction has been delivered!"
[ActiveJob] [SendSmsJob] [35941177-...] Performed SendSmsJob (Job ID: 35941177-...) from Async(default) in 2.7ms
```

Note the number is masked in the log line: phone numbers are PII and the
adapter never writes one in full.

## 2. Request latency when the provider is slow

Measured on 2026-09-25 against the earlier Rails 7.1 build. The request path
(controller, catalogue check, `perform_later`) has not changed since.

The provider was made to take 1.5 s per call (an `sleep(1.5)` patched into
the log adapter for the duration of this measurement only). Three requests
each way, same server, same session:

```
### Current code: the controller enqueues, a worker calls the provider
  POST /messages  total=0.012357s  status=302
  POST /messages  total=0.008233s  status=302
  POST /messages  total=0.008247s  status=302

### Original shape: the controller calls the provider inline
  POST /messages  total=1.533889s  status=302
  POST /messages  total=1.523286s  status=302
  POST /messages  total=1.515564s  status=302
```

≈1.52 s → ≈8 ms on the request thread, because the request no longer waits
on the third party. With Puma's default 5 threads, the inline version
saturates at roughly 3 requests/second during a provider slowdown; the
queued version is bounded by the database instead.

## 3. Health check

```
$ curl -s -o /dev/null -w "status=%{http_code}\n" http://127.0.0.1:18860/up
status=200

$ curl -s -o /dev/null -w "status=%{http_code} redirect=%{redirect_url}\n" http://127.0.0.1:18860/
status=302 redirect=http://127.0.0.1:18860/users/sign_in
```

## 4. Action Cable

A raw WebSocket handshake to `/cable` with the `actioncable-v1-json`
subprotocol, once with no cookie and once with the session cookie of a
signed-in user. The first frame the server sent back:

```
anonymous : HTTP/1.1 101 Switching Protocols {"type":"disconnect","reason":"unauthorized","reconnect":false}
signed in : HTTP/1.1 101 Switching Protocols {"type":"welcome"}
```

The server logged the first as `An unauthorized connection attempt was
rejected`. The signed-in connection subscribes to its internal channel
through Redis, which is why production needs `REDIS_URL`.

## 5. Test suite

```
$ bundle exec rspec
............................................................
Finished in 2.21 seconds (files took 1.27 seconds to load)
60 examples, 0 failures

Coverage report generated for RSpec to coverage/index.html
Line coverage: 149 / 155 (96.12%)
```

## 6. The suite can fail

Recorded on 2026-09-25, when the suite had 57 examples. Each fixed defect was
reintroduced one at a time and the suite re-run, to confirm the tests are
load-bearing rather than decorative:

| Mutation | Result |
| --- | --- |
| `MessageCatalog.user_triggerable?` always returns `true` | 57 examples, **6 failures** |
| Controller trusts `params[:user_id]` instead of `current_user` | 57 examples, **1 failure** |
| Welcome SMS moved back into `after_create` with `raise ActiveRecord::Rollback` | 57 examples, **5 failures** |
| all reverted | 57 examples, 0 failures |

## 7. Linter and dependency audit

```
$ bundle exec rubocop
52 files inspected, no offenses detected

$ bundle-audit check --update
No vulnerabilities found
```
