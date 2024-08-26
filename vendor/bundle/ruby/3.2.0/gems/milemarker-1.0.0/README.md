# Milemarker -- track (and probably log) progress in batch jobs

Never again write code of the
form `log.info "Finished 1_000 in #{secs} seconds at a rate of #{total.to_f / secs}"`
.

## Usage

```ruby

require 'milemarker'
require 'logger'
input_file = "records.ndj"

# Create a new milemarker. Default batch_size is 1_000
milemarker     = Milemarker.new(name: "Load #{input_file}", batch_size: 1_000_000)
logger = Logger.new(STDERR)

milemarker.logger = logger

File.open(input_file).each do |line|
  do_whatever_needs_doing(line)
  milemarker.increment_and_log_batch_line
end
milemarker.log_final_line # if logging is set up

# Identical to the above, but do the logging "by hand"
File.open(input_file).each do |line|
  do_whatever_needs_doing(line)
  milemarker.increment_and_on_batch { logger.info milemarker.batch_line }
end
logger.info milemarker.final_line

# Sample output
# ...
# I, [2021-11-02T01:51:06.959137 #11710]  INFO -- : load records.ndj   8_000_000. This batch 2_000_000 in 26.2s (76_469 r/s). Overall 72_705 r/s.
# I, [2021-11-02T01:51:36.992831 #11710]  INFO -- : load records.ndj  10_000_000. This batch 2_000_000 in 30.0s (66_591 r/s). Overall 71_394 r/s.
# ...
# I, [2021-11-02T02:01:56.702196 #11710]  INFO -- : load records.ndj FINISHED. 27_138_118 total records in 00h 12m 39s. Overall 35_718 r/s.

```

## Basic usage

Most programs will probably use `milemarker` is via
`#increment_and_log_batch_line`
(or its counterpart `#increment_and_on_batch {|milemarker| ... }` ). As 
the name suggests, this will:

* increment the batch counter
* If the batch counter >= the batch size:
  * run the provided block (or write the logline)
  * reset count/time/etc for the next batch

Some examples:

```ruby

# Logging, as above
milemarker = Milemarker.new(batch_size: 1000, name: 'Load myfile')
milemarker.increment_and_on_batch { logger.info milemarker.batch_line }

# Alert when things seem to to take too long

milemarker.increment_and_on_batch do |milemarker|
  secs = milemarker.last_batch_seconds
  if secs > way_too_long
    logger.error "Whoa: #{secs} is too long for a batch of #{milemarker.batch_size}"
  end
end

# #on_batch and #increment_and_on_batch can be used to do real (i.e., 
# non-logging) work after every `batch` calls, too
queue = []
my_stuff.each do |doc|
  queue << do_something_to(doc)
  milemarker.increment_and_on_batch do |milemarker|
    write_to_datastore(queue)
    queue = []
    logger.info milemarker.batch_line
  end
end
```

`#incr` and `#on_batch(&blk)` are also available separately if you need to be
more explicit and less atomic.

All the components that make up a batch_line (e.g., the records/second as 
a nice string) are available to roll your own batch line. See the API 
documentation for details. 

### Incorporating a logger into milemarker

For standard logging cases, you can also pass in a logger, or let milemarker
create one for its own use based on an IO-like object you provide

```ruby
logger = Logger.new(STDERR)
milemarker     = Milemarker.new(name: 'my_process', batch_size: 10_000, logger: logger)

# same thing
milemarker        = Milemarker.new(name: 'my_process', batch_size: 10_000)
milemarker.logger = logger

# same thing again
milemarker = Milemarker.new(name: 'my_process', batch_size: 10_000)
milemarker.create_logger!(STDERR)

File.open(input_file).each do |line|
  do_whatever_needs_doing(line)
  milemarker.increment_and_log_batch_line
end

milemarker.log_final_line

# All the logging methods take an optional :level argument
milemarker.log_final_line(level: :debug)

```

### Structured logging with Milemarker::Structured

`Milemarker::Structured` will return hashes for `#batch_line` and `#final_line`
(aliased to `#batch_data` and `#final_data`, respectively) and pass those
hashes along to whatever logger you provide. `#create_logger!` for this
subclass will create a logger that provides json lines instead of text, too.

Presumably, if you pass in your own logger you'll use something like
[semantic_logger](https://github.com/reidmorrison/semantic_logger)
or [ougai](https://github.com/tilfin/ougai).

```ruby
milemarker = Milemarker::Structured.new(name: 'my_process', batch_size: 10_000)
milemarker.create_logger!(STDERR)

File.open(input_file).each do |line|
  do_whatever_needs_doing(line)
  milemarker.increment_and_log_batch_line
end

# Usually one line; broken up for readability
# {"name":"my_process","batch_count":10_000,"batch_seconds":97.502088,
# "batch_rate":1.035875252230496,"total_count":100,"total_seconds":97.502094,
# "total_rate":1.0358751884856956,"level":"INFO","time":"2021-11-06 17:32:21 -0400"}

```

## Threadsafety

A call to `milemaker.threadsafify!` will wrap `increment_and_on_batch` (and
`increment_and_log_batch_line`) to be a threadsafe atomic operation at the 
cost of some performance. 

```
milemarker.threadsafify!

```

## Turning off logging

If the logger is set to `nil`, no logging will occur.

```ruby
# Turn off logging

milemarker.logger = nil
```

You could also just configure your logger to ignore stuff

```ruby

milemarker.logger.level = :error

```

## Accuracy

Note that `milemarker` isn't designed for real benchmarking. The assumption is
that whatever work your code is actually doing will drown out any
inefficiencies in the `milemarker` code, and milemarker numbers can be used to suss out 
where weird things are happening. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'milemarker'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install milemarker


## Contributing

Bug reports and pull requests are welcome on GitHub
at https://github.com/billdueber/milemarker.

## License

The gem is available as open source under the terms of
the [MIT License](https://opensource.org/licenses/MIT).
