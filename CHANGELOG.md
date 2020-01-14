## v0.3.1

Bugfix:
* Fix sentry integration while logging messages different than exceptions

## v0.3.0

Improvements:
* Handle AR connections correctly (hook in Rails < 5, reloader implementation in Rails >= 5)
* Allow to specify Rails app folder to require

New features:
* Add sentry integration

## v0.2.0

### Breaking changes

* Retry queue now uses direct exchange with routing (prevent message duplicating on retry)
* Change API to be much more universal
* Auto ACK on job success

### Other

* Add batching

## v0.1.0

* Initial version
