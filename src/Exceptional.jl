cnt = 0

struct BlockInterruption <: Exception
  lbl::Symbol
  val::Any
end

function block(func::Function)
  global cnt
  lbl = Symbol("__", :func, cnt) # This symbol should be unique in the program
  cnt += 1
  try
    func(lbl)
  catch e
    if (e isa BlockInterruption) && (e.lbl == lbl)
      return e.val
    else
      rethrow()
    end
  end
end

function return_from(lbl::Symbol, val=nothing)
  throw(BlockInterruption(lbl, val))
end

function available_restart(name::Symbol)
  # TODO: Check of restart is available
end

function invoke_restart(name::Symbol, args...)
  # TODO: Invoke restart: name(args..)
end

function restart_bind(func::Function, restarts...)
  # TODO: bings restarts to a functions?
end

function error(exception::Exception)
  # TODO: Introspectable exception?
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
        handle(e)
        break
      end
    end
    # Always rethrow
    rethrow()
  end
end
