abstract type ControlException <: Exception end

struct BlockInterruption <: ControlException
  lbl::Symbol   # current active label
  val::Any      # block return value
end

struct Restart <: ControlException
  name::Symbol  # restart name
  args          # arguments to be passed to restart
end

# global counter
let cnt = 0
  global counter() = (cnt += 1)
end

active_blocks = []
handler_bindings = []
restart_bindings = Dict()

function block(func::Function)
  global active_blocks
  # create unique sym
  lbl = Symbol("#$(counter())#", :func)
  push!(active_blocks, lbl)
  try
    func(lbl)
  catch e
    if isa(e, BlockInterruption) && (e.lbl == lbl)
      return e.val
    else
      rethrow()
    end
  finally
    pop!(active_blocks)
  end
end

function return_from(lbl::Symbol, val=nothing)
  global active_blocks
  if in(lbl, active_blocks)
    throw(BlockInterruption(lbl, val))
  else
    Base.error("control-error")
  end
end

function available_restart(name::Symbol)
  global restart_bindings 
  return haskey(restart_bindings, name)
end

function invoke_restart(name::Symbol, args...)
  throw(Restart(name, args))
end

function restart_bind(func::Function, restarts...)
  global restart_bindings
  original_restarts = copy(restart_bindings)
  current_restarts  = Dict(restart for restart in restarts)
  restart_bindings  = merge!(restart_bindings, current_restarts)
  try
    func()
  catch e
    if isa(e, Restart)
      if haskey(restart_bindings, e.name)
        return (restart_bindings[e.name])(e.args...)
      else
        Base.error("control-error")
      end
    else
      rethrow()
    end
  finally
    restart_bindings = original_restarts
  end
end

function error(exception::Exception)
  global handler_bindings
  for binding in handler_bindings
    etype = binding.first
    handle = binding.second
    if isa(exception, etype)
      handle(exception)
    end
  end
  Base.error("$(exception) was not handled.")
end

function handler_bind(func::Function, handlers...)
  global handler_bindings
  original_binds   = copy(handler_bindings)
  current_binds    = [handler for handler in handlers]
  handler_bindings = vcat(current_binds, handler_bindings)
  try
    func()
  catch
    rethrow()
  finally
    handler_bindings = original_binds
  end
end
