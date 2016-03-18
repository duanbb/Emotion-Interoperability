function SortedCell = Map2SortedCell(Map)
    keys = Map.keys;
    SortedCell = cell(length(keys), 2); %��map��value����ʱ��Ҫ��תΪN*2��cell array��Ȼ���cell array�ĵڶ�������
    for i = 1:length(keys)
        SortedCell{i,1} = keys{i}; %ΪcellԪ�ظ�ֵ��ͳһ��{}
        SortedCell{i,2} = Map(keys{i});
    end
    clear i
    SortedCell = flipud(sortrows(SortedCell,2));
end