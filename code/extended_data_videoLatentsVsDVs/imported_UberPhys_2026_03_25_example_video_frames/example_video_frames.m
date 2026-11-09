vid=VideoReader("X:\tzluo\analysis_data\analysis_2024_11_04a_behavioral_videos\concatented_video_segments\video_@PBups_Adrian_A324_230721a.mp4")
clear f;vid.CurrentTime=0;for i=1:45;frame = vid.readFrame;f(:,:,i) = frame(:,:,1);end
figure;for i=1:45;subplot(7,7,i);imagesc(f(:,:,i));axis square;colormap gray;end;
