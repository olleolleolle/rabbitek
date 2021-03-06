## v0.4.0

Improvements:
* Add metrics (universal, you can use e.g. prometheus)

## v0.3.5

Bugfix:
* Fix OpenTracing support when there is no trace_id incoming with job.

## v0.3.4

Improvements:
* Logging improvement

## v0.3.3

Improvements:
* Failure in retry hook will result in additional logging and nacking job with requeue: true

## v0.3.2

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
