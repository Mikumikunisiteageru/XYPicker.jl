# src/XYPicker.jl

module XYPicker

using PyPlot

export xypicker

points = Tuple{Int,Float64,Float64}[]

plots = []

function click(event)
	type = event.button
	x = event.xdata
	y = event.ydata
	push!(points, (type, x, y))
	append!(plots, plot(x, y, "r."))
end

function xypicker(imgpath::AbstractString; slot=click)
	img = imread(imgpath)
	imshow(img)
	gcf().canvas.mpl_connect("button_press_event", click)
end

end # module XYPicker
