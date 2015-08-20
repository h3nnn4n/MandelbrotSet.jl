screenx = 800
screeny = 600

xcenter = (-0.650)
ycenter = ( 0.0)

zoom    = (-1.500)

minx    = (xcenter + zoom)
maxx    = (xcenter - zoom)
miny    = (ycenter + zoom)
maxy    = (ycenter - zoom)

iters   = 150

function load_pal(name)
    file_pal = open(name, "r")

    for i in 1:4
        dump = readline(file_pal)
    end

    pal = Array((Int, Int, Int), 255)

    pivot :: Int = 0

    r, g, b = 0, 0, 0

    while eof(file_pal) == false && pivot < 255
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
            #=write(out, uint8(255))=#
            #=write(out, uint8(255))=#
            #=write(out, uint8(255))=#
            write(out, uint8(p[1]))
            write(out, uint8(p[2]))
            write(out, uint8(p[3]))
        end
    end
end

function mandel(c)
    z = Complex(0.0, 0.0)

    for i = 1:iters
        z = z^2 + c

        if abs(z)>2.0
            return (i, z)
        end
    end

    return (0, z)
end

function main()
    pal = load_pal("pals/reds.ppm")

    bitmap_c     = Array((Int64, Complex), (screenx, screeny))
    bitmap_color = Array((Int, Int, Int) , (screenx, screeny))

    max = 0

    for x in 1:screenx, y in 1:screeny
        real = minx + x*(maxx-minx)/screenx
        imag = miny + y*(maxy-miny)/screeny
        c = Complex(real, imag)

        bitmap_c[x, y] = mandel(c)

        if bitmap_c[x, y][1] > max
            max = bitmap_c[x, y][1]
        end
    end

    max = 255 / max

    for x in 1:screenx, y in 1:screeny
        if bitmap_c[x, y][1] == 0
            bitmap_color[x, y] = (0, 0, 0)
        else
            bitmap_color[x, y] = get_color(pal, int(bitmap_c[x, y][1] * max))
        end
    end

    ppm_write(bitmap_color)

end

main()

