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

	struct StrategyResult { double blocksSeenRatio, blocksMinedRatio, diamondsSeenRatio; }

	StrategyResult testStrategy(STRATEGY strategy, int xtile, int ytile, int ztile)
	{
		bool seen[] = new bool[diamonds.length];
		StrategyResult r;

		int probes = xtile*ytile*ztile;
		assert(probes > 0);

		int diamondsSeen;

		foreach (int xshift; 0..xtile)
			foreach (int yshift; 0..ytile)
				foreach (int zshift; 0..ztile)
				{
					seen[] = false;

					void checkDiamond(int x, int y, int z)
					{
						int id = getDiamondAt(x, y, z);
						if (id>=0 && !seen[id])
						{
							seen[id] = true;
							diamondsSeen++;
							checkDiamond(x-1, y, z);
							checkDiamond(x+1, y, z);
							checkDiamond(x, y-1, z);
							checkDiamond(x, y+1, z);
							checkDiamond(x, y, z-1);
							checkDiamond(x, y, z+1);
						}
					}

					foreach (ref d; diamonds)
					{
						int x = d.x + xshift;
						int y = d.y + yshift;
						int z = d.z + zshift;

						if (strategy(x, y, z)
						 || strategy(x-1, y, z)
						 || strategy(x+1, y, z)
						 || strategy(x, y-1, z)
						 || strategy(x, y+1, z)
						 || strategy(x, y, z-1)
						 || strategy(x, y, z+1))
							checkDiamond(d.x, d.y, d.z);
					}
				}

		int blocksMined, blocksSeen;

		foreach (int x; 0..xtile)
			foreach (int y; 2..2+ytile)
				foreach (int z; 0..ztile)
					if (strategy(x, y, z))
						blocksMined++, blocksSeen++;
					else
					if (strategy(x-1, y, z)
					 || strategy(x+1, y, z)
					 || strategy(x, y-1, z)
					 || strategy(x, y+1, z)
					 || strategy(x, y, z-1)
					 || strategy(x, y, z+1))
						blocksSeen++;

		r.blocksSeenRatio = cast(double)blocksSeen / probes;
		r.blocksMinedRatio = cast(double)blocksMined / probes;
		r.diamondsSeenRatio = cast(double)diamondsSeen / probes / diamonds.length;

		return r;
	}

	writefln("%-20s%16s%16s%16s%16s", "Strategy", "Blocks seen", "Blocks mined", "Diamonds seen", "Work / diamond");

	void printResults(string name, StrategyResult r)
	{
		writefln("%-20s%15.2f%%%15.2f%%%15.2f%%%16.2f",
			name,
			r.blocksSeenRatio  *100.0,
			r.blocksMinedRatio *100.0,
			r.diamondsSeenRatio*100.0,
			(totalBlocks * r.blocksMinedRatio) / (r.diamondsSeenRatio * diamonds.length));
	}

	printResults("Everything", testStrategy(function(int x, int y, int z) { return true; }, 1, 1, 1));

	{
		static int hi, vi, sl;
		for (vi=2; vi<=7; vi++)
			for (hi=2; hi<=16; hi++)
				for (sl=0; sl<=hi/2; sl++)
					printResults(format("Galleries[v%d,h%d,s%d]", vi, hi, sl), testStrategy(function(int x, int y, int z) { return y%vi<2 && floorMod(x, hi) == y/vi * sl % hi; }, hi, vi, 1));
	}
}

auto floorMod(T)(T a, T b) { auto m = a%b; return m>=0 ? m : m + b; }
