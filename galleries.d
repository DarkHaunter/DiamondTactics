import std.stdio;
import std.string;

auto floorMod(T)(T a, T b) { auto m = a%b; return m>=0 ? m : m + b; }

alias bool function(int, int, int) STRATEGY;

void evaluateStrategy(string name, STRATEGY strategy)
{
	writeln(name);
	for (int y=16; y>=1; y--)
	{
		for (int x=0; x<32; x++)
			write(strategy(x, y, 0) ? " " : 
				strategy(x-1, y, 0) || strategy(x+1, y, 0) || strategy(x, y-1, 0) || strategy(x, y+1, 0) ? "\u2592" : "\u2588" );
		writeln();
	}
}

void main()
{
	static int hi, vi, sl;
	for (vi=2; vi<=7; vi++)
		for (hi=2; hi<=16; hi++)
			for (sl=0; sl<=hi/2; sl++)
				evaluateStrategy(format("=== Galleries[v%d,h%d,s%d] ===", vi, hi, sl), function(int x, int y, int z) { return y%vi<2 && floorMod(x, hi) == y/vi * sl % hi; });
}
