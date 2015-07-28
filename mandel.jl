#=@everywhere screenx = 1920=#
#=@everywhere screeny = 1080=#
@everywhere screenx = 800
@everywhere screeny = 600

@everywhere xcenter = (-0.743030)
@everywhere ycenter = ( 0.126433)

@everywhere zoom    = ( 0.51)

@everywhere minx    = (xcenter + zoom)
@everywhere maxx    = (xcenter - zoom)
@everywhere miny    = (ycenter + zoom)
@everywhere maxy    = (ycenter - zoom)

@everywhere stepx   = (screenx/(maxx-minx))
@everywhere stepy   = (screeny/(maxy-miny))

@everywhere iters   = 600

@everywhere function mandel(c)
    z = 0.0
    for i = 1:iters
        z = z^2 + c
        if abs(z)>2.0
            w = int( ((i + 1 - log2(log2(abs(z)))) / iters) * 255)
            #=w = int((i + 1 - log(log(abs(z)))/log(2)) / iters) * 255=#
            #=println(w)=#
            return w
        end
    end
    return 0
end

@everywhere function getPixel(I)
    e = Array(Int64, (size(I[1],1), size(I[2],1)))

    xmin = I[1][1] - 1
    ymin = I[2][1] - 1

    for y = I[2]
        for x = I[1]
            c = Complex(minx + x*(maxx-minx)/screenx, miny + y*(maxy-miny)/screeny)
            e[x-xmin, y-ymin] = mandel(c)
        end
    end

    return e
end

function load_pal(name)
    file_pal = open(name, "r")

    dump = readline(file_pal)
    dump = readline(file_pal)
    dump = readline(file_pal)
    dump = readline(file_pal)

    pal = Array((Int, Int, Int), 255)

    pivot :: Int = 0

    r, g, b = 0, 0, 0

    while eof(file_pal) == false
        pivot += 1

        r = int(readline(file_pal))
        g = int(readline(file_pal))
        b = int(readline(file_pal))

        pal[pivot] = (r, g, b)
    end

    return pal
end

    #=tic()=#
    #=println("Maximum took:    \t", toq())=#

function get_color(pal, index)
    if index == 0
        index += 1
    end

    return pal[index]
end

function ppm_write(img)
    out = open("out.ppm", "w")

    write(out, "P6\n")
    x, y = size(img)
    write(out, "$x $y 255\n")

    #=for i = 1:x, j = 1:y=#
    for j = 1:y, i = 1:x
        p = img[i,j]

        if p == (0,0,0)
            write(out, uint8(0))
            write(out, uint8(0))
            write(out, uint8(0))
        else
            write(out, uint8(p[1]))
            write(out, uint8(p[2]))
            write(out, uint8(p[3]))
        end
    end
end

function main()
    println("\nStarting")

    tic()
    pal = load_pal("pals/sunrise2.ppm")

    timert :: Float64 = toq()
    timer  :: Float64 = timert

    println("Pallete loading took:\t", timert)

    ################################################

    tic()
    @sync dist_bitmap = DArray(getPixel, (screenx, screeny))

    #=bm = [Complex(minx + x*(maxx-minx)/screenx, miny + y*(maxy-miny)/screeny) for x in 0:screenx, y in 0:screeny]=#

    timert = toq()
    timer += timert

    println("Iterating took:  \t", timert)

    ################################################

    tic()
    @sync bitmap = convert(Array, dist_bitmap)

    #=bitmap = pmap(mandel, bm)=#

    timert = toq()
    timer += timert

    println("Conversion took: \t", timert)

    ################################################

    tic()
    max = maximum(bitmap)
    max /= 255

    #=histogram = Array(Int, iters+1)=#
    histogram = Array(Int, 256)
    fill!(histogram, 0)

    x, y = size(bitmap)
    bitmap2 = Array(Int, (x, y))

    for i = 1:x, j = 1:y
        bitmap2[i,j] = int64(bitmap[i,j] / max)
        teste = bitmap[i, j]
        #=print(teste, " ")=#

        if bitmap[i, j] == 0

        else
            #=println(bitmap[i, j] + 1, " ")=#
            histogram[ bitmap[i, j] + 1 ] += 1
        end
    end

    total_hist = sum(histogram)

    timert = toq()
    timer += timert

    println("Normalization took:\t", timert)

    ################################################

    tic()
    bitmap_color = Array((Int, Int, Int), (x,y))
    #=fill!(bitmap_color, (0, 0, 0))=#

    for i in 1:x, j in 1:y
        if bitmap[i, j] == 0
            bitmap_color[i, j] = (0, 0, 0)
        else

            # Normalized histogram
            hue = 0.0
            for k in 1:bitmap[i, j]
                hue += float(histogram[k] / total_hist)
            end

            bitmap_color[i, j] = get_color(pal, int(hue * 254)+1)

            # Intiger escape time
            #=bitmap_color[i, j] = get_color(pal, bitmap2[i, j])=#
        end
    end

    timert = toq()
    timer += timert

    println("Colouring took:  \t", timert)

    ################################################

    tic()
    ppm_write(bitmap_color)

    timert = toq()
    timer += timert

    println("Salving took:    \t", timert)

    ################################################

    println("Total time was:  \t", timer)

    println("Done\n\n")
end

main()

#=@profile main()=#
#=Profile.print()=#
