# V112 changelog

- Fixed a profile persistence race between corrupt-primary self-healing reads and concurrent save/remove mutations.
- Recovery writes now run through the same process-wide mutation queue as save/remove and re-read storage once queued.
- save/remove use a private non-enqueueing reader while holding the queue, avoiding recursive queue deadlock.
- Added a Flutter regression test covering concurrent recovery + save.
- Flutter/Dart execution remains unverified in this environment.
