function WorkerAnnotation = ImportData(File, Labels, Name_column, Start_column)
    [~, textdata] = xlsread(['Input\', File]);
    system('taskkill /F /IM EXCEL.EXE'); clear ans
    workers = textdata(2:end,Name_column)';%��һ����title��Ҫȥ��
    for i = 1:length(workers) %��ȡÿһ�����ݣ���ÿ��worker�����ݣ�
        annotation_text = textdata(i+1,Start_column:end);%��һ�к�ǰ������title��Ҫȥ��
        annotation = struct;
        annotations = cell(0);
        for j = 1:length(annotation_text)
            label_ordinal = mod(j,length(Labels)+1); %��Ϊ��һ��mu������Ҫ��1
            if label_ordinal == 0
                %worker_annotation.(workers{i})
                 annotations{j/(length(Labels)+1),1} = annotation; %cell�ڶ�̬�ر䣬���д洢
                 clear annotation
                 continue
            end
            cur_label = Labels{label_ordinal};
            if strcmp(annotation_text{j},'') %0:false, 1:true
                annotation.(cur_label) = false;
            else
                annotation.(cur_label) = true;
            end
            clear cur_label label_ordinal
        end
        clear j annotation_text
        WorkerAnnotation.(workers{i}) = CellArray2StructArray(annotations);
    end
    clear i
end