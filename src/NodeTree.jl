## A Module To create a node tree ##

module NodeTree

export AbstractTree, AbstractRoot, AbstractNode
export Node
export ObjectRoot, ObjectTree

abstract type AbstractTree end
abstract type AbstractRoot end
abstract type AbstractNode end

## A Simple Dictionary interface to keep track of nodes
# Won't be exported
struct SimpleDict{T <: Any,N <: Any}
	ky :: Vector{T}
	vl :: Vector{N}

	## Constructors ##

	SimpleDict() = new{Any,Any}([],[])
	SimpleDict{T,N}() where{T <: Any, N <: Any} = new{T,N}(T[],N[])
end

Base.length(d::SimpleDict) = length(getfield(d,:ky))

function Base.getindex(d::SimpleDict,ky)
	key = getfield(d,:ky)
	
	@inbounds for i in eachindex(key)
		if ky == key[i]
			return getfield(d,:vl)[i]
		end
	end

	error("There is no key $ky in dictionary")
	return
end

function Base.setindex!(d::SimpleDict,v,ky)
	key = getfield(d,:ky)
	value = getfield(d,:vl)
	if ky in key
		for i in eachindex(key)
			if (key[i] == ky) 
				value[i] = v 
				return 
			end
		end
	else
		push!(key,ky)
		push!(value,v)
	end
end

@nospecialize
function Base.in(k,d::SimpleDict)
	return k in getfield(d,:ky)
end
@specialize

function Base.delete!(d::SimpleDict,elt)
	key = getfield(d,:ky)
	val = getfield(d,:vl)
	for i in eachindex(key)
		if key[i] == elt
			deleteat!(key,i)
			deleteat(val,i)
		end
	end
end

Base.length(d::SimpleDict) = length(getfield(d,:ky))

"""
	struct Node

A struct to create a Node for an abstract tree.
"""
mutable struct Node{T} <: AbstractNode
	self :: T
	ID :: UInt
	tree :: WeakRef
	parentID :: UInt

	name :: String
	childrens :: Vector{UInt}

	Node(obj,name=_generate_node_name();index=1) = new{typeof(obj)}(obj,index,WeakRef(nothing),0,name,UInt[])
	Node{T}(obj::T,name=_generate_node_name();index=1) where T= new{T}(obj,(index,),name,UInt[])
end

"""
	struct ObjectRoot <: AbstractRoot

A structure to use as a root for an ObjectTree. He his the one containing all node.
"""
struct ObjectRoot <: AbstractRoot
	childs :: Vector{UInt}
	tree :: WeakRef

	ObjectRoot() = new(UInt[],WeakRef(nothing))
	ObjectRoot(childs::Vector{UInt}) = new(childs,WeakRef(nothing))
end

""""
	struct ObjectTree <: AbstractTree

An object to create Tree of object. He his the one managing everything, and contain all
The real objects

# Example

```julia-script

using .NodeTree

tree = ObjectTree()
NodeTree.get_tree() = tree

a = [[1,2],[3,4]]
n1 = Node([1,2,3],"Array")
n2 = Node([4,5,6],"Array2")
n3 = Node([7,8,9],"Array3")

add_child(tree,n1)
add_child(tree,n2)
add_child(tree,n3)

n4 = Node(57,"Int Yo")
n5 = Node(789,"Int Yay")

add_child(n1,n4)
add_child(n1,n5)

n6 = Node(3.4,"Floating")
n7 = Node(rand(),"Floating+")
n8 = Node(rand()*10,"Floating+++")
n9 = Node(eps(),"Floating+++")

add_child(n2,n6)
add_child(n2,n7)
add_child(n7,n8)
add_child(n2,n9)

n10 = Node("Yay","String")
add_child(n3,n10)

print_tree(stdout,tree)
print_tree(stdout,a)

```
"""
mutable struct ObjectTree <: AbstractTree
	objects :: SimpleDict{UInt,Node}
	root :: ObjectRoot
	node_count :: UInt
	current_ID :: UInt

	ObjectTree() = begin
		tree = new(SimpleDict{UInt,Node}(),ObjectRoot(),0,0)
		get_root(tree).tree.value = tree
		return tree 
	end
	ObjectTree(root::ObjectRoot) = begin
		tree = new(SimpleDict{UInt,Node}(),root,0,0)
		root.tree.value = tree
		return tree 
	end
end

include("interface.jl")
include("operations.jl")
include("baseTree.jl")
include("printing.jl")
include("LinkedNode.jl")

_generate_node_name() = "@Node"

end