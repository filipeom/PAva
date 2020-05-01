cnt = 0

res = Pair[]

struct BlockException <: Exception
  lbl 
  val
end

function block(func::Function)
  lbl = "L$(cnt)"
  global cnt += 1
  try
    func(lbl)
  catch e
    if (e isa BlockException) && (e.lbl == lbl)
      return e.val
    else
      rethrow()
    end
  end
end

function return_from(lbl::String, val=nothing)
  throw(BlockException(lbl, val))
end

function available_restart(name)
  # TODO: Check of restart is available
end

function invoke_restart(name, args...)
  # TODO: execute restart with the args provided
end

function restart_bind(func, restarts...)
  # TODO: Make restarts available
  func
end

function error(exception::Exception)
  # XXX: What should this function do? other than throw an except?
  throw(exception)
end

function handler_bind(func::Function, handlers...)
  try
    func()
  catch e
    for pair in handlers
      e_type = pair.first
      handle = pair.second 
      if e isa e_type
        handle(e_type)
        break
      end
    end
    # always rethrow
    rethrow()
  end
end
