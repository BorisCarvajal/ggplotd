module ggplotd.axes;

version(unittest)
{
    import dunit.toolkit;
}

///
struct Axis
{
    ///
    this(double newmin, double newmax)
    {
        min = newmin;
        max = newmax;
        min_tick = min;
    }

    ///
    string label;
    ///
    double min = -1;
    ///
    double max = 1;
    ///
    double min_tick = -1;
    ///
    double tick_width = 0.2;
}


/**
    Calculate optimal tick width given an axis and an approximate number of ticks
    */
Axis adjustTickWidth(Axis axis, size_t approx_no_ticks)
{
    import std.math : abs, floor, ceil, pow, log10;
    auto axis_width = axis.max - axis.min;
    auto scale = cast(int) floor(log10(axis_width));
    auto acceptables = [0.1, 0.2, 0.5, 1.0, 2.0, 5.0]; // Only accept ticks of these sizes
    auto approx_width = pow(10.0, -scale) * (axis_width) / approx_no_ticks;
    // Find closest acceptable value
    double best = acceptables[0];
    double diff = abs(approx_width - best);
    foreach (accept; acceptables[1 .. $])
    {
        if (abs(approx_width - accept) < diff)
        {
            best = accept;
            diff = abs(approx_width - accept);
        }
    }
    axis.tick_width = best * pow(10.0, scale);
    // Find good min_tick
    axis.min_tick = ceil(axis.min * pow(10.0, -scale)) * pow(10.0, scale);
    //debug writeln( "Here 120 ", axis.min_tick, " ", axis.min, " ", 
    //		axis.max,	" ", axis.tick_width, " ", scale );
    while (axis.min_tick - axis.tick_width > axis.min)
        axis.min_tick -= axis.tick_width;
    return axis;
}

unittest
{
    adjustTickWidth(Axis(0, .4), 5);
    adjustTickWidth(Axis(0, 4), 8);
    assert(adjustTickWidth(Axis(0, 4), 5).tick_width == 1.0);
    assert(adjustTickWidth(Axis(0, 4), 8).tick_width == 0.5);
    assert(adjustTickWidth(Axis(0, 0.4), 5).tick_width == 0.1);
    assert(adjustTickWidth(Axis(0, 40), 8).tick_width == 5);
    assert(adjustTickWidth(Axis(-0.1, 4), 8).tick_width == 0.5);
    assert(adjustTickWidth(Axis(-0.1, 4), 8).min_tick == 0.0);
    assert(adjustTickWidth(Axis(0.1, 4), 8).min_tick == 0.5);
    assert(adjustTickWidth(Axis(1, 40), 8).min_tick == 5);
    assert(adjustTickWidth(Axis(3, 4), 5).min_tick == 3);
    assert(adjustTickWidth(Axis(3, 4), 5).tick_width == 0.2);
    assert(adjustTickWidth(Axis(1.79877e+07, 1.86788e+07), 5).min_tick == 1.8e+07);
    assert(adjustTickWidth(Axis(1.79877e+07, 1.86788e+07), 5).tick_width == 100000);
}

/// Returns a range starting at axis.min, ending axis.max and with
/// all the tick locations in between
auto axisTicks( Axis axis )
{
    struct Ticks
    {
        double currentPosition;
        Axis axis;

        @property double front()
        {
            if (currentPosition >= axis.max)
                return axis.max;
            return currentPosition;
        }

        void popFront()
        {
            if (currentPosition < axis.min_tick)
                currentPosition = axis.min_tick;
            else
                currentPosition += axis.tick_width;
        }

        @property bool empty() 
        {
            if (currentPosition - axis.tick_width >= axis.max)
                return true;
            return false;
        }
    }

    return Ticks( axis.min, axis );
}

unittest
{
    import std.array : array, front, back;

    auto ax1 = adjustTickWidth(Axis(0, .4), 5).axisTicks;
    auto ax2 = adjustTickWidth(Axis(0, 4), 8).axisTicks;
    assertEqual( ax1.array.front, 0 );
    assertEqual( ax1.array.back, .4 );
    assertEqual( ax2.array.front, 0 );
    assertEqual( ax2.array.back, 4 );
    assertGreaterThan( ax1.array.length, 3 );
    assertLessThan( ax1.array.length, 8 );

    assertGreaterThan( ax2.array.length, 5 );
    assertLessThan( ax2.array.length, 10 );

    auto ax3 = adjustTickWidth(Axis(1.1, 2), 5).axisTicks;
    assertEqual( ax3.array.front, 1.1 );
    assertEqual( ax3.array.back, 2 );
}
 
/// Calculate tick length
double tickLength(in Axis axis)
{
    return (axis.max - axis.min) / 25.0;
}

unittest
{
    auto axis = Axis(-1, 1);
    assert(tickLength(axis) == 0.08);
}