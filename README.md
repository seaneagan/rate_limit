rate_limit
==========

[![Build Status](https://drone.io/github.com/seaneagan/rate_limit/status.png)](https://drone.io/github.com/seaneagan/rate_limit/latest)

Provides the following StreamTransformers to limit the rate at which a Stream emits events.

##Throttler

Enforces a wait period between events.

```dart
// Avoid excessively updating the position while scrolling.
window.onScroll
 .transform(new Throttler(const Duration(milliseconds: 100)))
 .forEach(updatePosition);
 
// Execute `renewToken` on click, but not more than once every 5 seconds.
querySelector('.interactive').onClick
 .transform(new Throttler(const Duration(seconds: 5), trailing: false))
 .forEach(renewToken);
```

##Debouncer

Enforces a *quiet* wait period between events.

```dart
// Avoid costly calculations while the window size is in flux.
window.onResize
 .transform(new Debouncer(const Duration(milliseconds: 150)))
 .forEach(calculateLayout);

// Execute `sendMail` on click, debouncing subsequent calls.
querySelector('#postbox').onClick
 .transform(new Debouncer(const Duration(milliseconds: 300), leading: true, trailing: false))
 .forEach(sendMail);

// Ensure `batchLog` is executed once after 1 second of debounced calls.
var source = new EventSource('/stream');
source.onMessage
 .transform(new Debouncer(const Duration(milliseconds: 250), maxWait: const Duration(seconds: 1)))
 .forEach(batchLog);
```

Inspired by lodash's [throttle](http://lodash.com/docs#throttle) and [debounce](http://lodash.com/docs#debounce).
