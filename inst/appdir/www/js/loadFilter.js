function myLoadFilter(data,parentId){
    function setData(){
        var todo = [];
        for(var i=0; i<data.length; i++){
            todo.push(data[i]);
        }
        while(todo.length){
            var node = todo.shift();
            if (node.children){
                node.state = 'closed';
                node.children1 = node.children;
                node.children = undefined;
                todo = todo.concat(node.children1);
            }
        }
    }
    
    setData(data);
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
    return data;
}