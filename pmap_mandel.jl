@everywhere screenx = 800
@everywhere screeny = 600
@everywhere screenx = 1920
@everywhere screeny = 1080

@everywhere xcenter = (-.743643887037151)
@everywhere ycenter = ( .131825904205330)

@everywhere zoom    = ( .000000000051299)

#=@everywhere xcenter = (-.743643900055)=#
#=@everywhere ycenter = ( .131825890901)=#

#=@everywhere zoom    = ( .000000049304)=#

#=@everywhere xcenter = (-.743643135)=#
#=@everywhere ycenter = ( .131825963)=#

#=@everywhere zoom    = ( .000014628)=#

#=@everywhere xcenter = (-0.743030)=#
#=@everywhere ycenter = ( 0.126433)=#

#=@everywhere zoom    = ( 0.0001251)=#

@everywhere minx    = (xcenter + zoom)
@everywhere maxx    = (xcenter - zoom)
@everywhere miny    = (ycenter + zoom)
@everywhere maxy    = (ycenter - zoom)

@everywhere stepx   = (screenx/(maxx-minx))
@everywhere stepy   = (screeny/(maxy-miny))

@everywhere iters   = 5000

@everywhere aa      = 1

@everywhere function mandel(c)
    dx = ((2 * zoom) / screenx) / (aa*2 + 1)
    dy = ((2 * zoom) / screeny) / (aa*2 + 1)

    bm = Array((Any), (aa*2 + 1, aa*2 + 1))

    for i in 1:(aa*2 + 1), j in 1:(aa*2 + 1)
        d = complex(dx * (i-aa), dy * (j-aa))
        bm[i, j] = m(c + d)
    end

    it = sum([ bm[i, j][1] for i in 1:(aa*2 + 1), j in 1:(aa*2 + 1) ]) / ((aa*2 + 1)^2)
    zz = sum([ bm[i, j][2] for i in 1:(aa*2 + 1), j in 1:(aa*2 + 1) ]) / ((aa*2 + 1)^2)

    return (it, zz)
end

@everywhere function m(c)
    z = 0.0
    for i = 1:iters
        z = z^2 + c
        if abs(z)>2.0
            w = (i, z)
            return w
        end
    end
    return (0, z)
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
    pal = load_pal("pals/reds.ppm")

    timert :: Float64 = toq()
    timer  :: Float64 = timert

    println("Pallete loading took:\t", timert)

    ################################################

    tic()

    cmap = Array(Complex, (screenx, screeny))

    for y in 1:screeny, x in 1:screenx
        cmap[x, y] = Complex(minx + x*(maxx-minx)/screenx, miny + y*(maxy-miny)/screeny)
    end

    timert = toq()
    timer += timert

    println("Preallocing took:  \t", timert)

    ################################################

    tic()

    bitmap_z = reshape(pmap(mandel, cmap, err_retry=true, err_stop=false), (screenx, screeny))

    timert = toq()
    timer += timert

    println("Iterating took:  \t", timert)

    ################################################

    tic()
    #=bitmap = reshape([ (bitmap_z[i, j][1] ) for i in 1:screenx, j in 1:screeny], (screenx, screeny))=#

    bitmap_t = Array(Float64, (screenx, screeny))

    for i in 1:screenx, j in 1:screeny
        if bitmap_z[i, j][1] == 0
            bitmap_t[i, j] = 0.0
        else
            mag = abs(bitmap_z[i, j][2])
            #=print("mag = ", mag, " ")=#
            #=print("log = ", log(mag), " \n")=#
            bitmap_t[i, j] = (bitmap_z[i, j][1] + 1 - log( abs(log(mag))) / log(2))
        end
    end

    #=histogram = Array(Int, iters+1)=#
    histogram = Array(Int, 255)
    fill!(histogram, 0)

    x, y = size(bitmap_t)

    max = maximum(bitmap_t) / 255

    println(max)

    bitmap = [ int(bitmap_t[i, j] / max) for i in 1:x, j in 1:y ]

    for i = 1:x, j = 1:y

        #=println(bitmap[i, j] )=#

        if bitmap[i, j] <= 0
            #=histogram[ 1 ] += 1=#
        else
            histogram[ bitmap[i, j] ] += 1
        end
    end

    total_hist = sum(histogram)


    timert = toq()
    timer += timert

    println("Normalization took:\t", timert)

    ################################################

    tic()
    bitmap_color = Array((Int, Int, Int), (x,y))

    for i in 1:x, j in 1:y
        if bitmap[i, j] == 0
            bitmap_color[i, j] = (0, 0, 0)
        else
            #=hue = 0.0=#
            #=for k in 1:bitmap[i, j]=#
                #=hue += float(histogram[k] / total_hist)=#
            #=end=#

            #=bitmap_color[i, j] = get_color(pal, int(hue * 254)+1)=#

            bitmap_color[i, j] = get_color(pal, bitmap[i, j])
            #=bitmap_color[i, j] = get_color(pal, (bitmap[i, j] * 4) % 255)=#
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
