struct BlockInterruption <: Exception
  lbl::Symbol
  val::Any
end

struct Restart <: Exception
  name::Symbol
  args
end

let cnt = 0
  global counter() = (cnt += 1)
end

env = []
handler_bindings = Dict()
restart_bindings = Dict()

function block(func::Function)
  global env
  lbl = Symbol("__", :func, counter())
  append!(env, [lbl])
  try
    func(lbl)
  catch e
    if (e isa BlockInterruption) && (e.lbl == lbl)
      return e.val
    else
      rethrow()
    end
  finally
    deleteat!(env, findfirst(isequal(lbl), env))
  end
end

function return_from(lbl::Symbol, val=nothing)
  global env
  if findfirst(isequal(lbl), env) == nothing
    println("No active label: \'$(lbl)\'")
  else
    throw(BlockInterruption(lbl, val))
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
  for pair in restarts
    name = pair.first
    restart = pair.second
    restart_bindings[name] = restart
  end
  try
    func()
  catch e
    if e isa Restart
      name = e.name
      args = e.args
      return (restart_bindings[name])(args...)
    else
      rethrow()
    end
  finally
    for pair in restarts
      name = pair.first
      delete!(restart_bindings, name)
    end
  end
end

function error(exception::Exception)
  global handler_bindings
  type = typeof(exception)
  if !haskey(handler_bindings, type)
    throw(exception)
  end
  for handle in handler_bindings[type]
    handle(exception)
  end
  Base.error("$(exception) was not handled.")
end

function handler_bind(func::Function, handlers...)
  global handler_bindings
  for pair in handlers
    type   = pair.first
    handle = pair.second
    if !haskey(handler_bindings, type) handler_bindings[type] = [] end
    pushfirst!(handler_bindings[type], handle)
  end
  try
    func()
  catch
    rethrow()
  finally
    for pair in handlers
      type = pair.first
      popfirst!(handler_bindings[type])
      if isempty(handler_bindings[type])
        delete!(handler_bindings, type)
      end
    end
  end
end
