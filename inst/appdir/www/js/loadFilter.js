  		function myLoadFilter(data){
			/*function setData(data){
				var nodes = [];
                // get the top level nodes
                for(var i=0; i<data.length; i++){
                    var row = data[i];
                    if (! row.hasOwnProperty('_parentId') ){
                        row.state = 'closed'
                        nodes.push(row);
                    }
                }
                
                var todo = [];
				for(var i=0; i<nodes.length; i++){
                    todo.push(nodes[i]);
				}
				while(todo.length){
					var node = todo.shift();
					if (node.haveSons == "TRUE"){
						node.state = 'closed';
						node.children1 = data.filter(row => row["_parentId"] === node.id);
						node.children = undefined;
						todo = todo.concat(node.children1);
					}
				}
                return nodes;
			}
            */
        dataTemp = JSON.parse(JSON.stringify(data.rows));
     
    function exists(data, parentId){
        for(var i=0; i<data.length; i++){
            if (data[i].id == parentId) return true;
        }
        return false;
    }
    
    var nodes = [];
    // get the top level nodes
    for(var i=0; i<dataTemp.length; i++){
        var row = dataTemp[i];
        if (!row.hasOwnProperty('_parentId')){
            nodes.push(row);
        }
    }
    var toDo = [];
    for(var i=0; i<nodes.length; i++){
        toDo.push(nodes[i]);
    }
    while(toDo.length){
        var node = toDo.shift();    // the parent node
        // get the children nodes
        for(var i=0; i<dataTemp.length; i++){
            var row = dataTemp[i];
            if (row['_parentId'] === node.id){
                var child = JSON.parse(JSON.stringify(row));;
                child.state = 'closed';
                child.id = parseInt(''+node.id+child.id);
                if (node.children){
                    node.children.push(child);
                } else {
                    node.children = [child];
                }
                toDo.push(child);
            }
        }
    }
   // alert(JSON.stringify(nodes));
    return nodes;
    
    /*
			nodes = setData(dataTemp);
			var tg = $(this);
			var opts = tg.treegrid('options');
			opts.onBeforeExpand = function(row){
				if (row.children1){
					tg.treegrid('append',{
						parent: row[opts.idField],
						data: row.children1
					});
					row.children1 = undefined;
					tg.treegrid('expand', row[opts.idField]);
				}
				return row.children1 == undefined;
			};
			return nodes; 
            */
		}