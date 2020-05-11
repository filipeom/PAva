struct BlockInterruption <: Exception
  lbl::Symbol
  val::Any
end

let cnt = 0
  global counter() = (cnt += 1)
end

# current active labels
env = []
# current active handler bindings
bindings = []
# current active restart bindings
restart_bindings = []

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
    # delete lbl from active environment
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
  # XXX: This check will change depending on the representation
  # of the restart_bindings
  global restart_bindings 
  for restart in restart_bindings
    sym = restart.first
    if name == sym
      return true
    end
  end
  return false
end

function invoke_restart(name::Symbol, args...)
  global restart_bindings
  ret_val = nothing
  for restart in restart_bindings
    sym = restart.first
    func = restart.second
    if sym == name
      ret_val = (func)(args) # This doesn't work, see introspectable functions from lab
      break
    end
  end
  return ret_val
end

function restart_bind(func::Function, restarts...)
  #= 
  ## TODO: All other restarts defined in the call chain
  ## should be available
  =#
  global restart_bindings 
  restart_bindings = restarts
  ret = func()
  restart_bindings = []
  return ret
end

function error(exception::Exception)
  global bindings
  ret = nothing
  for handler in bindings
    e_type = handler.first
    handle = handler.second
    if exception isa e_type
      ret = handle(exception)
      if ret != nothing
        break
      end
    end
  end
  if ret != nothing
    return ret
  else
    throw(exception)
  end
end

function handler_bind(func::Function, handlers...)
  #= 
  ## TODO: All other bindings defined in the call chain
  ## should be available
  =#
  global bindings
  bindings = handlers
  try
    func()
  catch e
    rethrow()
  finally
    bindings = []
  end
end
