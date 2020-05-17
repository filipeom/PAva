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

# current active labels
env = []
# current active handler bindings
bindings = Dict()
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
  throw(Restart(name, args))
end


function restart_bind(func::Function, restarts...)
  #= 
  ## TODO: All other restarts defined in the call chain
  ## should be available
  =#
  try
    func()
  catch e
    if e isa Restart
      name = e.name
      args = e.args
      for pair in restarts
        if name == pair.first
          return (pair.second)(args[1])
        end
      end
    end
  end
end

function error(exception::Exception)
  global bindings
  type = typeof(exception)
  if !haskey(bindings, type)
    throw(exception)
  end
  for handle in bindings[type]
    handle(exception)
  end
  throw(exception)
end

function handler_bind(func::Function, handlers...)
  global bindings
  for pair in handlers
    type   = pair.first
    handle = pair.second
    if !haskey(bindings, type) bindings[type] = [] end
    pushfirst!(bindings[type], handle)
  end
  try
    func()
  catch
    rethrow()
  finally
    for pair in handlers
      type = pair.first
      popfirst!(bindings[type])
      if isempty(bindings[type])
        delete!(bindings, type)
      end
    end
  end
end
