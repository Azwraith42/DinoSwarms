package dinosaurs.Engines
{
	
	import flash.geom.Point;
	
	import dinosaurs.Dinosaur;
	import dinosaurs.Engines.Node;
	
	import island.TileMap;
	import island.tiles.Tile;
	
	public class AStar
	{
		protected var _nodePos:Array; //quick Node pos look up
		protected var _allNodes:Array; //quick Node look up
		protected var _openList:Array; // Looked at Nodes
		protected var _start:Node; //Starting Node
		protected var _end:Point; //Ending coordinates
		protected var _currentNode:Node; //Current Node being processed
		
		protected var _dino:Dinosaur; //needed for different pathing costs 
		
		public function AStar(startX:Number, startY:Number, endX:Number, endY:Number, dino:Dinosaur)
		{
			//setting variables and current node
			_end.x = endX;
			_end.y = endY;
			_start = new Node(startX, startY, null, 0, GenerateHeuristic(startX, startY), 1);
			_currentNode = _start;
			//start at position 1 to make later math easier
			_openList[1] = _start;
			_allNodes[startX][startY] = _start;
			_nodePos[startX][startY] = 1;
			
			_dino = dino;
		}
		
		private function GeneratePath():Array
		{
			//copy of current map
			var Map:TileMap = TileMap.CurrentMap();
			//core path finding loop
			while(_openList.length > 0)
			{
				//next node always at top of priority heap
				_currentNode = _openList[0];
				var _Pos:Point = _currentNode.Coordinate();
				//did we reach our goal?
				if (_Pos == _end)
				{
					break;
				}
				
				//Loop through all Neighbors
				for (var i:int = -1; i < 2; i++)
				{
					for (var j:int = -1; j < 2; j++)
					{
						//don't count the current node
						if (i == 0 && j == 0)
							continue;
						
						//don't count untraversable nodes
						if (!Map.getTileFromCoord(_Pos.x + i, _Pos.y + j).getTraversable())
							continue;
						
						var tempNode:Node = new Node(_Pos.x + i, _Pos.y + j, _Pos, _currentNode.CostSoFar()
							+ GenerateCost(TileMap.CurrentMap.getTile(_Pos.x + i, _Pos.y + j)),
							GenerateHeuristic(_Pos.x + i, _Pos.y + j), 1);
						
						if (_allNodes[_Pos.x + i][_Pos.y + j] != null)
						{
							if (_allNodes[_Pos.x + i][_Pos.y + j].EstimatedCost > tempNode.EstimatedCost)
							{
								if (_allNodes[_Pos.x + i][_Pos.y + j].State == 1)
								{
									UpdateOpenList(tempNode);
									_allNodes[_Pos.x + i][_Pos.y + j] = tempNode;
								}
								else
								{
									AddOpenList(tempNode);
									_allNodes[_Pos.x + i][_Pos.y + j] = tempNode;
								}
							}
							else
								continue;
						}
						else
						{
							AddOpenList(tempNode);
							_allNodes[_Pos.x + i][_Pos.y + j] = tempNode;
						}
					}
				}
				PopOpenList();
				_currentNode.setState(2);
				_allNodes[_Pos.x][_Pos.y] = _currentNode;
			}
			if (_currentNode.Coordinate != _end)
				return null;
			
			else
			{
				var returnList:Array;
				returnList[0] = _currentNode;
				while (_currentNode != _start)
				{
					_currentNode = _allNodes[_currentNode.Connection.x][_currentNode.Connection.y];
					returnList[returnList.length - 1] = _currentNode;
				}
				
				return returnList;
			}
		}
		
		private function AddOpenList(NewNode:Node):void
		{
			//get last position in open list and Estimated Cost of the new node
			var newCost:Number = NewNode.EstimatedCost();
			var currPos:int = _openList.length;
			
			_openList[currPos] = NewNode;
			
			//sorts the new node up the tree based on its cost
			while (true)
			{
				if (newCost < _openList[currPos / 2].EstimatedCost())
				{
					_openList[currPos] = _openList[currPos / 2];
					_openList[currPos / 2] = NewNode;
					currPos = currPos / 2;
				}
				
				else
				{
					_nodePos[NewNode.Coordinate.x][NewNode.Coordinate.y] = currPos;
					break;
				}
			}
			
		}
		
		private function PopOpenList():void
		{
			_openList[1] = _openList.pop();
			var currPos:int = 1;
			var tmpNode:Node = _openList[1];
			
			while (true)
			{
				if (_openList[ (2 * currPos)].EstimatedCost < _openList[ (2 * currPos) + 1].EstimatedCost)
				{
					if (tmpNode.EstimatedCost > _openList[ (2 * currPos)].EstimatedCost)
					{
						_openList[currPos] = _openList[ (2 * currPos)];
						_openList[ (2 * currPos)] = tmpNode;
					}
					
					else
					{
						break;
					}
				}
				else
				{
					if (tmpNode.EstimatedCost > _openList[ (2 * currPos) + 1].EstimatedCost)
					{
						_openList[currPos] = _openList[ (2 * currPos) + 1];
						_openList[ (2 * currPos) + 1] = tmpNode;
					}
						
					else
					{
						break;
					}
				}
			}
		}
		
		private function UpdateOpenList(RefNode:Node):void
		{
			var newCost:Number = RefNode.EstimatedCost();
			var currPos:int = _nodePos[RefNode.Coordinate.x][RefNode.Coordinate.y];
			
			_openList[currPos] =RefNode;
			
			//sorts the ref node up the tree based on its cost
			while (true)
			{
				if (newCost < _openList[currPos / 2].EstimatedCost())
				{
					_openList[currPos] = _openList[currPos / 2];
					_openList[currPos / 2] = RefNode;
					currPos = currPos / 2;
				}
					
				else
				{
					_nodePos[RefNode.Coordinate.x][RefNode.Coordinate.y] = currPos;
					break;
				}
			}
			
		}
		
		private function GenerateCost(tile:Tile):int
		{
			return _dino.MoveCost(tile);
		}
		
		private function GenerateHeuristic(nodeX:int, nodeY:int):Number{
			//Uses Euclidain distance as heuristic
			//Currently just a linear 1:1 cost
			var dx:Number = Math.abs(_end.x - nodeX);
			var dy:Number = Math.abs(_end.y - nodeY);
			return Math.sqrt(Math.pow(dx,2) + Math.pow(dy,2));
		}
		
	}
}