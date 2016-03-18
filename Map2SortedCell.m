function SortedCell = Map2SortedCell(Map)
    keys = Map.keys;
    SortedCell = cell(length(keys), 2); %对map按value排序时，要先转为N*2的cell array，然后对cell array的第二列排序
    for i = 1:length(keys)
        SortedCell{i,1} = keys{i}; %为cell元素赋值，统一用{}
        SortedCell{i,2} = Map(keys{i});
    end
    clear i
    SortedCell = flipud(sortrows(SortedCell,2));
end