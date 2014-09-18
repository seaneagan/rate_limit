
library rate_limit_test;

import 'dart:async';

import 'package:rate_limit/rate_limit.dart';
import 'package:unittest/unittest.dart';
import 'package:fake_async/fake_async.dart';

main() {
  group('Debouncer', () {

    test('should throw when both `leading` and `trailing` are false', () {
      expect(
          () => new Debouncer(const Duration(seconds: 1), leading: false, trailing: false), 
          throwsArgumentError);
    });

    test('should throw when `wait` is less than `maxWait`', () {
      expect(
          () => new Debouncer(const Duration(seconds: 2), maxWait: const Duration(seconds: 1)), 
          throwsArgumentError);
    });

    test('should wait to add first event when `leading` is false', () {
      return new Future(() {
          new FakeAsync().run((async) {
          var controller = new StreamController<String>(sync: true);
          var unit = new Debouncer<String>(const Duration(seconds: 2));
          var debounced = unit.bind(controller.stream);
          var expectation = debounced.map((event) => [event, async.elapsed]).toList().then((eventsAndTimes) {
            expect(eventsAndTimes, [['e', async.elapsed]]);
          });
          controller.add('e');
          async.elapse(const Duration(seconds: 2));
          controller.close();
          return expectation;
        });
      });
    });

    test('should add previous event when wait period expires', () {
      return new Future(() {
        return new FakeAsync().run((async) {
          var controller = new StreamController<String>(sync: true);
          var unit = new Debouncer<String>(const Duration(seconds: 2));
          var debounced = unit.bind(controller.stream);
          Duration firstTime;
          var expectation = debounced.map((event) => [event, async.elapsed]).toList().then((eventsAndTimes) {
            expect(eventsAndTimes, [
              ['first', firstTime],
              ['second', async.elapsed]
            ]);
          });

          var i = 0;
          thrash() {
            for(int j = 0; j < 10; j++) {
              controller.add('should be swallowed #$i');
              async.elapse(const Duration(seconds: 1));
            }
          }
          
          thrash();
          controller.add('first');
          async.elapse(const Duration(seconds: 2));
          firstTime = async.elapsed;
          
          thrash();
          controller.add('second');
          async.elapse(const Duration(seconds: 2));
          
          controller.close();
          return expectation;
        });
      });
    });

    test('should emit previous event once `maxWait` has expired', () {
      return new Future(() {
        return new FakeAsync().run((async) {
          var controller = new StreamController<String>(sync: true);
          var unit = new Debouncer<String>(const Duration(seconds: 2), maxWait: const Duration(seconds: 10));
          var debounced = unit.bind(controller.stream);
          var expectation = debounced.map((event) => [event, async.elapsed]).toList().then((eventsAndTimes) {
            expect(eventsAndTimes, [
              ['9', const Duration(seconds: 10)],
              ['19', async.elapsed]
            ]);
          });

          for(int i = 0; i < 20; i++) {
            controller.add('$i');
            async.elapse(const Duration(seconds: 1));
          }
          controller.close();

          return expectation;
        });
      });
    });

    test('should emit event immediately when `leading` is true and not in wait period', () {
      return new Future(() {
        return new FakeAsync().run((async) {
          var controller = new StreamController<String>(sync: true);
          var unit = new Debouncer<String>(const Duration(seconds: 2), leading: true);
          var debounced = unit.bind(controller.stream);
          var expectation = debounced.map((event) => [event, async.elapsed]).toList().then((events) {
            expect(events, [
              ['leading', Duration.ZERO],
              ['trailing', async.elapsed]
            ]);
          });
          controller.add('leading');
          async.elapse(const Duration(seconds: 1));
          controller.add('swallowed');
          async.elapse(const Duration(seconds: 1));
          controller.add('trailing');
          async.elapse(const Duration(seconds: 2));
          controller.close();
          return expectation;
        });
      });
    });
    
    group('Throttler', () {

      test('should throw when both `leading` and `trailing` are false', () {
        expect(
            () => new Throttler(const Duration(seconds: 1), leading: false, trailing: false), 
            throwsArgumentError);
      });
      
      test('should throttle', () {
        return new Future(() {
          return new FakeAsync().run((async) {
            var controller = new StreamController<String>(sync: true);
            var unit = new Throttler<String>(const Duration(seconds: 2));
            var debounced = unit.bind(controller.stream);
            var expectation = debounced.map((event) => [event, async.elapsed]).toList().then((eventsAndTimes) {
              expect(eventsAndTimes, [
                ['0', const Duration(seconds: 0)],
                ['1', const Duration(seconds: 2)],
                ['2', const Duration(seconds: 2)],
                ['3', const Duration(seconds: 4)],
              ]);
            });

            for(int i = 0; i < 4; i++) {
              controller.add('$i');
              async.elapse(const Duration(seconds: 1));
            }
            controller.close();

            return expectation;
          });
        });
      });
    });
  });
}
