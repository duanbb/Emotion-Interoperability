function BN = LearnBN(SourceGolds, SourceTaxonomy, TargetAnnotations, TargetTaxonomy, filename) 
    source_labels = fieldnames(SourceTaxonomy);
    target_labels = fieldnames(TargetTaxonomy);
    n_sentences = length(SourceGolds);
    workers = fieldnames(TargetAnnotations);
    n_workers = length(workers);

    %% �����¼�����cases_matrix 
    %For use with structure learning and full parameters learning.
    %(casescases_matrix(i,m) is the value of node i in case m)
    sentence_workers = GetSentenceWorkers(TargetAnnotations);
    n_cases_complete = 0;% �¼�����������
    for i = 1:n_sentences
       n_cases_complete = n_cases_complete + length(sentence_workers{i});
    end
    n_labels = length(source_labels) + length(target_labels);
    cases_matrix = ones(n_labels, n_cases_complete); %�У�label�����У��¼�����������*��������
    % ����source���¼���events�����source���֣�
    for i = 1:length(source_labels) %ȡ��ÿһ��source label���У�
        start_column = 1;
        for j = 1:n_sentences %ȡ��ÿһ�����ӣ��У�
            end_column = start_column + length(sentence_workers{j}) - 1;
            if SourceGolds(j).(source_labels{i})
               cases_matrix(SourceTaxonomy.(source_labels{i}),start_column:end_column) = 2; %���У�label����ֵ��label��ID������������
            end
            start_column = end_column + 1;
            clear end_column
        end
        clear j start_column
    end
    clear i
    % ����target���¼���events�����target���֣�
    for i = 1:length(target_labels) %ȡ��ÿ��target label���У�
        cur_column = 0;
        for j = 1:n_sentences %ȡ��ÿ��sentence���еĵ�һ���֣�
            for k = 1:length(sentence_workers{j}) %ȡ��ÿ��worker���еĵڶ����֣�
                cur_column = cur_column + 1;
                if TargetAnnotations.(sentence_workers{j}{k})(j).(target_labels{i})
                   cases_matrix(TargetTaxonomy.(target_labels{i}),cur_column) = 2; %label��ID������������
                end
            end
            clear k
        end
        clear j cur_column
    end
    clear i
    
    %% get node_sizes
    ns = 2*ones(1,n_labels);
    
    %% learn structure
    global VARIABLES
    if strcmp(VARIABLES.struct_learning, 'K2')
        % get source label order
        source_label_freq_map = containers.Map();
        for i = 1:length(source_labels)
           source_label_freq_map(source_labels{i}) = 0;
        end
        clear i
        % �����ڸ����Gold�У���label���ֵ�Ƶ��
        for i = 1:n_sentences %ÿһ������
            for j = 1:length(source_labels) %ÿһ��label
                if SourceGolds(i).(source_labels{j}) %��ǰlabelΪtrue
                    source_label_freq_map(source_labels{j}) = source_label_freq_map(source_labels{j}) + 1;
                end
            end
            clear j
        end
        clear i
        source_order = Map2Order(source_label_freq_map, SourceTaxonomy);
        % get target label order
        target_label_freq_map = containers.Map();
        for i = 1:length(target_labels)
            target_label_freq_map(target_labels{i}) = 0;
        end
        clear i
        for i = 1:n_workers %ȡÿ��worker
            for j = 1:length(TargetAnnotations.(workers{i})) %ȡ��worker��ÿ��annotation
                cur_annotation = TargetAnnotations.(workers{i})(j);
                if ~isempty(cur_annotation) %�жϴ�worker�Ƿ���˴�sentence
                    for k = 1:length(target_labels) %ȡÿ��label
                        if cur_annotation.(target_labels{k})
                            target_label_freq_map(target_labels{k}) = target_label_freq_map(target_labels{k}) + 1;
                        end
                    end
                    clear k
                else
                    f;
                end
                clear cur_annotation
            end
            clear j
        end
        clear i
        target_order = Map2Order(target_label_freq_map, TargetTaxonomy);
        BN.Order = [source_order, target_order];
        BN.DAG = VARIABLES.struct_learning(cases_matrix, ns, BN.Order, 'max_fan_in', n_labels); %n_labels: default
    elseif strcmp(VARIABLES.struct_learning, 'MCMC')
        [dag, accept_ratio, num_edges] = learn_struct_mcmc(cases_matrix, ns);
        BN.DAG = dag{end}; %Խ����Խ��
    else
        error('Wrong VARIABLES.struct_learning: %s', VARIABLES.struct_learning);
    end
    %g=Dag+Dag'; %һ��Ҫת�ɶԳƲ�����ʾ���Գ�Ϊ����ͼ�����Գ�Ϊ����ͼ������ͼ��BUG��ֻ��������ͼ���棬�����ɵ�ͼ��һ���Ǵ���ָ���£����Է�������
    %draw_graph(g, Label_names);
    all_labels = {'N_ϲ'; 'N_��'; 'N_��'; 'N_ŭ'; 'N_��'; 'N_��'; 'N_�u'; 'N_��'; 'N_��'; 'N_�@'; ...
        'E_anger'; 'E_sadness'; 'E_joy'; 'E_disgust'; 'E_surprise'; 'E_fear'};
    adj2pajek2(BN.DAG, ['Output\', filename], all_labels); %�������ļ����ٵ��뵽pajek�(source��һ����target֮ǰ���˴�Ҫ��label�ı���ID˳�������С�)
    
    %%  Learn Parameters ���Ʋ������������ʣ�
    original_net = mk_bnet(BN.DAG, ns); %ת�Ƹ���(parameters)ΪĬ��ֵʱ��NET
    for i = 1:n_labels
        original_net.CPD{i} = tabular_CPD(original_net, i);
    end
    clear i
    if strcmp(VARIABLES.params_learn, 'Complete')
        BN.Net = learn_params(original_net, cases_matrix);
    elseif strcmp(VARIABLES.params_learn, 'Missing')
        %get cases_cell
        n_cases_missing = n_sentences * n_workers; %������*����
        cases_cell = cell(n_labels, n_cases_missing);
        % ����source���¼���events�����source���֣�
        for i = 1:length(source_labels) %ȡ��ÿһ��source label���У�
            start_column = 1;
            for j = 1:n_sentences %ȡ��ÿһ�����ӣ��У�
                end_column = start_column + n_workers - 1;
                if SourceGolds(j).(source_labels{i})
                    cases_cell(SourceTaxonomy.(source_labels{i}),start_column:end_column) = num2cell(2*ones(1,n_workers)); %���У�label����ֵ��label��ID������������
                else 
                    cases_cell(SourceTaxonomy.(source_labels{i}),start_column:end_column) = num2cell(ones(1,n_workers));
                end
                start_column = end_column + 1;
                clear end_column
            end
            clear j start_column
        end
        clear i
        % ����target���¼���events�����target���֣�
        for i = 1:length(target_labels) %ȡ��ÿ��target label���У�
            cur_column = 0;
            for j = 1:n_sentences %ȡ��ÿ��sentence���еĵ�һ���֣�
                for k = 1:n_workers %ȡ��ÿ��worker���еĵڶ����֣�
                    cur_column = cur_column + 1;
                    if ~isempty(TargetAnnotations.(workers{k})(j).(target_labels{i}))
                        if TargetAnnotations.(workers{k})(j).(target_labels{i})
                            cases_cell{TargetTaxonomy.(target_labels{i}),cur_column} = 2; %label��ID������������
                        else
                            cases_cell{TargetTaxonomy.(target_labels{i}),cur_column} = 1;
                        end
                    end
                end
                clear k
            end
            clear j cur_column
        end
        clear i
        
        engine = VARIABLES.inference_engine(original_net);
        BN.Net = learn_params_em(engine, cases_cell); % very slow
    else
        error('Wrong VARIABLES.params_learn: %s', VARIABLES.params_learn);
    end
    
    % �鿴ѧϰ������������
    BN.CPT = cell(n_labels,1);
    for i = 1:n_labels
        s = struct(BN.Net.CPD{i}); % violate object privacy
        BN.CPT{i} = s.CPT;
        %dispcpt(Matching.CPT{i});
    end
end

%% Subfunction
function Order = Map2Order(Map, Taxonomy)
    sorted_label_freq_cell = Map2SortedCell(Map);
    labels = Map.keys;
    Order = zeros(1,length(labels));
    for i = 1:length(labels)
        Order(i) = Taxonomy.(sorted_label_freq_cell{i,1});
    end
    clear i
end