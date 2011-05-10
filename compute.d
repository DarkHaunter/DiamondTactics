// Written in the D Programming Language, version 2

import std.stdio;
import std.string;

import common;
alias common.chunks chunks;

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
							foreach (v; VECTORS_DIAGONAL)
								checkDiamond(x+v.x, y+v.y, z+v.z);
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
