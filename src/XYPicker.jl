# src/XYPicker.jl

module XYPicker

using LinearAlgebra
using PyPlot

export getpoints, clearpoints, clearplots, clearboth
export xypicker
export Transformer, transformer

const LEFT = 1
const RIGHT = 3

points = Tuple{Int,Float64,Float64}[]

function getpoints(; mode=:allright)
	if mode == :allright
		return reduce(vcat, [p[2] p[3]] for p = points if p[1] == RIGHT)
	elseif mode == :allleft
		return reduce(vcat, [p[2] p[3]] for p = points if p[1] == LEFT)
	elseif mode == :all
		return reduce(vcat, [p[2] p[3]] for p = points)
	elseif mode == :newright
		x = findlast
	else
		return points
	end
end

function clearpoints()
	global points = Tuple{Int,Float64,Float64}[]
	return nothing
end

plots = []

function clearplots()
	for p = plots
		p.remove()
	end
	global plots = []
	return nothing
end

function clearboth()
	clearpoints()
	clearplots()
end

function click(event)
	type = event.button
	x = event.xdata
	y = event.ydata
	push!(points, (type, x, y))
	if type == LEFT
		append!(plots, plot(x, y, "r."))
	elseif type == RIGHT
		append!(plots, plot(x, y, "b."))
	else
		error("Unrecognized button type {type}!")
	end
end

function xypicker(imgpath::AbstractString; slot=click)
	img = imread(imgpath)
	imshow(img)
	gca().set_position([0, 0, 1, 1])
	gcf().canvas.mpl_connect("button_press_event", click)
end

struct Transformer <: Function
	m::Matrix{Float64}
end

function transformer(xyfrom::AbstractMatrix{<:Real}, 
		xyto::AbstractMatrix{<:Real})
	nt, mt = size(xyto)
	nf, mf = size(xyfrom)
	@assert nt == nf > 1
	@assert mt == 2
	@assert 2 <= mf <= 3
	if mf == 2
		xyfrom = hcat(xyfrom, ones(eltype(xyfrom), nf))
	end
	return Transformer(pinv(xyfrom) * xyto)
end

function Base.inv(t::Transformer)
	a, b, e, c, d, f = t.m
	invdet = inv(a * d - b * c)
	A = invdet * d
	B = invdet * -b
	C = invdet * -c
	D = invdet * a
	E = invdet * (b*f - d*e)
	F = invdet * (c*e - a*f)
	M = [A C; B D; E F]
	return Transformer(M)
end

function (t::Transformer)(xyfrom::AbstractMatrix{<:Real})
	nf, mf = size(xyfrom)
	@assert 2 <= mf <= 3
	if mf == 2
		xyfrom = hcat(xyfrom, ones(eltype(xyfrom), nf))
	end
	return xyfrom * t.m
end

end # module XYPicker
