# Captured output

Everything below was produced by running this application locally on
2026-09-25: Ruby 3.2.2, Rails 7.1.2, PostgreSQL 16, the Rails server on
port 8860, no Twilio credentials configured (so the `log` adapter is
active). Commands and responses are copied verbatim.

## 1. The message allow-list

`POST /messages` accepts a catalogue *key*, never message text. Only keys
flagged `user_triggerable` are accepted; `welcome` is system-only.

```
$ curl -X POST /messages -d "message_key=transaction_success"
  -> HTTP 302, 0.010969s
  flash[status]: Send transaction success SMS queued for +14••••••671.

$ curl -X POST /messages -d "message_key=welcome"
  -> HTTP 302, 0.007354s
  flash[alert]: That message is not one you can send.

$ curl -X POST /messages -d "message_key=Call 1-900-PREMIUM to claim your prize"
  -> HTTP 302, 0.007555s
  flash[alert]: That message is not one you can send.
```

Only the first request enqueued anything:

```
[ActiveJob] Enqueued SendSmsJob (Job ID: 2c4caa70-cadc-4bca-87e6-b9b27da26345) to Async(default) with arguments: {:user_id=>1, :message_key=>"transaction_success"}
[ActiveJob] [SendSmsJob] [2c4caa70-...] [sms:log] to=+14••••••671 body="Hey Ada Lovelace, your transaction has been delivered!"
[ActiveJob] [SendSmsJob] [2c4caa70-...] Performed SendSmsJob (Job ID: 2c4caa70-...) from Async(default) in 1.6ms
```

Note the number is masked in the log line: phone numbers are PII and the
adapter never writes one in full.

## 2. Request latency when the provider is slow

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
$ curl -s -o /dev/null -w "status=%{http_code}\n" http://127.0.0.1:8860/up
status=200

$ curl -s -o /dev/null -w "status=%{http_code} redirect=%{redirect_url}\n" http://127.0.0.1:8860/
status=302 redirect=http://127.0.0.1:8860/users/sign_in
```

## 4. Test suite

```
$ bundle exec rspec
.........................................................
Coverage report generated for RSpec to .../coverage. 144 / 178 LOC (80.9%) covered.

Finished in 0.88629 seconds (files took 1.49 seconds to load)
57 examples, 0 failures
```

### The suite can fail

Each fixed defect was reintroduced one at a time and the suite re-run, to
confirm the tests are load-bearing rather than decorative:

| Mutation | Result |
| --- | --- |
| `MessageCatalog.user_triggerable?` always returns `true` | 57 examples, **6 failures** |
| Controller trusts `params[:user_id]` instead of `current_user` | 57 examples, **1 failure** |
| Welcome SMS moved back into `after_create` with `raise ActiveRecord::Rollback` | 57 examples, **5 failures** |
| all reverted | 57 examples, 0 failures |

## 5. Linter

```
$ bundle exec rubocop
54 files inspected, no offenses detected
```
