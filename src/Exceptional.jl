struct BlockInterruption <: Exception
  lbl::Symbol   # current active label
  val::Any      # block return value
end

struct Restart <: Exception
  name::Symbol  # restart name
  args          # arguments to be passed to restart
end

# global counter
let cnt = 0
  global counter() = (cnt += 1)
end

env = []
handler_bindings = []
restart_bindings = Dict()

function block(func::Function)
  global env
  # create unique sym
  lbl = Symbol("#$(counter())#", :func)
  push!(env, lbl)
  try
    func(lbl)
  catch e
    if isa(e, BlockInterruption) && (e.lbl == lbl)
      return e.val
    else
      rethrow()
    end
  finally
    pop!(env)
  end
end

function return_from(lbl::Symbol, val=nothing)
  global env
  if in(lbl, env)
    throw(BlockInterruption(lbl, val))
  else
    Base.error("$(lbl) was not found in the referencing environment.")
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
  for restart in restarts
    restart_bindings[restart.first] = restart.second
  end
  try
    func()
  catch e
    if isa(e, Restart)
      return (restart_bindings[e.name])(e.args...)
    else
      rethrow()
    end
  finally
    for restart in restarts
      delete!(restart_bindings, restart.first)
    end
  end
end

function error(exception::Exception)
  global handler_bindings
  pos = findfirst((x)->isa(exception, x.first), handler_bindings)
  handlers = handler_bindings[pos].second
  if !isempty(handlers)
    for handle in handlers
      handle(exception)
    end
  end
  Base.error("$(exception) was not handled.")
end

function handler_bind(func::Function, handlers...)
  global handler_bindings
  for handler in handlers
    cnd = handler.first
    hdl = handler.second
    pos = findfirst((x)->isequal(x.first, cnd), handler_bindings)
    if pos == nothing
      push!(handler_bindings, cnd => Any[hdl])
    else
      pushfirst!(handler_bindings[pos].second, hdl)
    end
  end
  try
    func()
  catch
    rethrow()
  finally
    # cleanup bindings
    for handler in handlers
      pos = findfirst((x)->isequal(x.first, handler.first), handler_bindings)
      popfirst!(handler_bindings[pos].second)
      if isempty(handler_bindings[pos].second)
        deleteat!(handler_bindings, pos)
      end
    end
  end
end
