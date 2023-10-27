# src/XYPicker.jl

module XYPicker

using LinearAlgebra
using PyPlot

export getpoints, clearall
export xypicker
export Transformer, transformer

const LEFT = 1
const RIGHT = 3

struct Record
	button::Int
	xdata::Float64
	ydata::Float64
end

isleft(r::Record) = r.button == LEFT
isright(r::Record) = r.button == RIGHT
sameas(r::Record) = isleft(r) ? isleft : isright
xyrow(r::Record) = [r.xdata r.ydata]

records = Record[]

function lastblock(func, records)
	i = findlast(!func, records)
	if isnothing(i)
		return records
	else
		return records[i+1:end]
	end
end

function filterrecords(; mode=:new)
	if mode == :all
		return records
	elseif mode == :allright
		return filter(isright, records)
	elseif mode == :allleft
		return filter(isleft, records)
	elseif mode == :new
		isempty(records) && return records
		return lastblock(sameas(records[end]), records)
	elseif mode == :newright
		return lastblock(isright, records)
	elseif mode == :newleft
		return lastblock(isleft, records)
	else
		error("Unrecognized mode $mode!")
	end
end

getpoints(; mode=:new) = 
	reduce(vcat, xyrow.(filterrecords(; mode=mode)); init=zeros(Float64,0,2))

function clearrecords()
	empty!(records)
	return nothing
end

plots = []

function clearplots()
	for p = plots
		p.remove()
	end
	empty!(plots)
	return nothing
end

function clearall()
	clearrecords()
	clearplots()
end

function click(event)
	button = event.button
	x = event.xdata
	y = event.ydata
	record = Record(button, x, y)
	push!(records, record)
	if isleft(record)
		append!(plots, plot(x, y, "r."))
	elseif isright(record)
		append!(plots, plot(x, y, "b."))
	else
		error("Unrecognized button type $button!")
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
