// Written in the D Programming Language, version 2

import std.stdio;
import std.string;
import std.conv;
import std.algorithm;

enum CHUNK_SIZE = 16;

struct Chunk { int x, z; }
Chunk[] chunks;

struct Diamond { int x, y, z; }
Diamond[] diamonds;

void loadData()
{
	foreach (line; File("chunks.csv").byLine)
	{
		auto chunkStrings = line.chomp().split(",");
		chunks ~= Chunk(to!int(chunkStrings[0]), to!int(chunkStrings[1]));
	}

	foreach (line; File("diamonds.csv").byLine)
	{
		auto diamondStrings = line.chomp().split(",");
		diamonds ~= Diamond(to!int(diamondStrings[0]), to!int(diamondStrings[1]), to!int(diamondStrings[2]));
	}
}

Chunk minChunk, maxChunk;
Diamond minDiamond, maxDiamond, size;
int[] map;

enum NO_DATA = -2;
enum NOT_DIAMOND = -1;

int offsetOf(int x, int y, int z)
{
	return
		(x - minDiamond.x) + 
		(y - minDiamond.y) * size.x + 
		(z - minDiamond.z) * size.y * size.x;
}

void getMinMax(T)(T[] records, out T minRecord, out T maxRecord)
{
	minRecord = records[0];
	maxRecord = records[0];

	foreach (ref record; records[1..$])
		foreach (i, field; record.tupleof)
		{
			minRecord.tupleof[i] = min(minRecord.tupleof[i], field);
			maxRecord.tupleof[i] = max(maxRecord.tupleof[i], field);
		}
}

void makeMap()
{
	getMinMax(diamonds, minDiamond, maxDiamond);
	getMinMax(chunks, minChunk, maxChunk);

	minDiamond.x = minChunk.x * CHUNK_SIZE;
	minDiamond.z = minChunk.z * CHUNK_SIZE;
	maxDiamond.x = maxChunk.x * CHUNK_SIZE + CHUNK_SIZE-1;
	maxDiamond.z = maxChunk.z * CHUNK_SIZE + CHUNK_SIZE-1;

	foreach (i, field; size.tupleof)
		size.tupleof[i] = maxDiamond.tupleof[i] - minDiamond.tupleof[i] + 1;

	map = new int[size.x * size.y * size.z];
	map[] = NOT_DIAMOND;
	foreach (int index, ref diamond; diamonds)
		map[offsetOf(diamond.tupleof)] = index;
}

int getDiamondAt(int x, int y, int z)
{
	if (x < minDiamond.x || y < minDiamond.y || z < minDiamond.z || x > maxDiamond.x || y > maxDiamond.y || z > maxDiamond.z)
		return NO_DATA;
	else
		return map[offsetOf(x, y, z)];
}

alias bool function(int, int, int) STRATEGY;

void main()
{
	loadData();
	makeMap();

	int totalBlocks = chunks.length * CHUNK_SIZE * CHUNK_SIZE * size.y;
	int totalDiamonds = diamonds.length;

	struct StrategyResult { int blocksSeen, blocksMined, diamondsSeen; }

	StrategyResult testStrategy(STRATEGY strategy)
	{
		bool seen[] = new bool[diamonds.length];
		StrategyResult r;

		void checkDiamond(int x, int y, int z)
		{
			int id = getDiamondAt(x, y, z);
			if (id>=0 && !seen[id])
			{
				seen[id] = true;
				r.diamondsSeen++;
				checkDiamond(x-1, y, z);
				checkDiamond(x+1, y, z);
				checkDiamond(x, y-1, z);
				checkDiamond(x, y+1, z);
				checkDiamond(x, y, z-1);
				checkDiamond(x, y, z+1);
			}
		}

		foreach (ref c; chunks)
			foreach (cx; 0..CHUNK_SIZE)
				foreach (cz; 0..CHUNK_SIZE)
				{
					int x = c.x * CHUNK_SIZE + cx;
					int z = c.z * CHUNK_SIZE + cz;
					foreach (y; minDiamond.y..maxDiamond.y+1)
					{
					    if (strategy(x, y, z))
					    {
					    	r.blocksMined++;
					    	r.blocksSeen++;
					    	checkDiamond(x, y, z);
					    }
					    else
					    if (strategy(x-1, y, z)
					     || strategy(x+1, y, z)
					     || strategy(x, y-1, z)
					     || strategy(x, y+1, z)
					     || strategy(x, y, z-1)
					     || strategy(x, y, z+1))
					    {
					     	r.blocksSeen++;
					     	checkDiamond(x, y, z);
					    }
					}
				}
		return r;
	}

	writefln("%-16s%16s%16s%16s%16s", "Strategy", "Blocks seen", "Blocks mined", "Diamonds seen", "Work / diamond");

	void evaluateStrategy(string name, STRATEGY strategy)
	{
		auto r = testStrategy(strategy);
		writefln("%-16s%15.2f%%%15.2f%%%15.2f%%%16.2f", name, r.blocksSeen*100.0/totalBlocks, r.blocksMined*100.0/totalBlocks, r.diamondsSeen*100.0/totalDiamonds, cast(float)r.blocksMined/r.diamondsSeen);
	}

	evaluateStrategy("Everything"   , function(int x, int y, int z) { return true;                          });
	evaluateStrategy("Zebra"        , function(int x, int y, int z) { return floorMod(x, 3) == 2;           });
	evaluateStrategy("Galleries"    , function(int x, int y, int z) { return floorMod(x, 4) == (y/2%2) * 2; });
	evaluateStrategy("Galleries/6"  , function(int x, int y, int z) { return floorMod(x, 6) == (y/2%2) * 3; });
	evaluateStrategy("Galleries/6s" , function(int x, int y, int z) { return floorMod(x, 6) == (y/2%3) * 2; });
	evaluateStrategy("Galleries/8"  , function(int x, int y, int z) { return floorMod(x, 8) == (y/2%2) * 4; });
	evaluateStrategy("Galleries/10" , function(int x, int y, int z) { return floorMod(x,10) == (y/2%2) * 5; });
	evaluateStrategy("Galleries/12" , function(int x, int y, int z) { return floorMod(x,12) == (y/2%2) * 6; });
	evaluateStrategy("Galleries/14" , function(int x, int y, int z) { return floorMod(x,14) == (y/2%2) * 7; });
	evaluateStrategy("Galleries/16" , function(int x, int y, int z) { return floorMod(x,16) == (y/2%2) * 8; });
	evaluateStrategy("Galleries/20" , function(int x, int y, int z) { return floorMod(x,20) == (y/2%2) *10; });
}

auto floorMod(T)(T a, T b) { auto m = a%b; return m>=0 ? m : m + b; }
