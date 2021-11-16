---
title: "Span Events"
weight: 3
---

An event is a human-readable message on a span that represents "something happening" during it's lifetime. For example, imagine a function that requires exclusive access to a resource that is under a mutex. An event could be created at two points - once, when we try to gain access to the resource, and another when we acquire the mutex.

```ruby
span.add_event("Acquiring lock")
if mutex.try_lock
  span.add_event("Got lock, doing work...")
  # some code here
  span.add_event("Releasing lock")
else
  span.add_event("Lock already in use")
end
```

A useful characteristic of events is that their timestamps are displayed as offsets from the beginning of the span, allowing you to easily see how much time elapsed between them.

Events can also have attributes of their own e.g.

```ruby
span.add_event("Cancelled wait due to external signal", attributes: { "pid" => 4328, "signal" => "SIGHUP" })
```
