 pro Extract_index
;   
;   ######################################################################
;   # Created on Jan, 2025                                               #
;   #                                                                    #
;   # Author: Danlu Cai, Department of Atmospheric Science,              #
;   #         University of Alabama in Huntsville                        #
;   #                                                                    #
;   # IDL+ENVI, manipulating Index from NAIP data                      #
;   #                                                                    #
;   ######################################################################

  COMPILE_OPT IDL2
  directory=DIALOG_PICKFILE(path = "\\uahdata\rgroup\urbanrs\Danlu_data\2024-Orlando_Administrative\7_Mosaic_10m\",/directory)
  cd,directory
  file_mkdir,directory+'\NDVI'
  file_mkdir,directory+'\NDWI'
  file_mkdir,directory+'\Texture'
  file_mkdir,directory+'\Brighness'
  
  envi, /restore_base_save_files
  envi_batch_init, log_file='batch.txt'
  list=findfile(directory+'*.HDR')
  result=size(list)
  filenum=result[1]
  print,'filenum = ',filenum
  
    for i=0,filenum-1,1 do begin
            filename = list[i]
            a = STRSPLIT(filename, '\', /EXTRACT)
            tmp = size(a)
            b = STRSPLIT(a[tmp[2]-1], '.', /EXTRACT)
            fname = b[0]
            print,"fname=",fname
            
            envi_open_file,list[i],r_fid=tfid
            print,'tfid = ', tfid

            envi_file_query, tfid, ns=ns, nl=nl, nb=nb
            dim=[-1,0,ns-1,0,nl-1]
            print,'dim = ', dim
            
              ;; NDVI
             posNDVI=[4,3]-1
             print,'out_name = ',directory+'\NDVI'+'\'+fname+'NDVI'
             envi_doit, 'ndvi_doit', $
                fid=tfid, pos=posNDVI, dims=dim, $
                /check, o_min=0, o_max=255, $
                out_name = directory+'\NDVI'+'\'+fname+'NDVI', r_fid=r_fid& catch,errorstatus
          
              ;; NDWI
              posNDWI=[2,4]-1
              print,'out_name = ',directory+'\NDWI'+'\'+fname+'NDWI'
              envi_doit, 'ndvi_doit', $
                fid=tfid, pos=posNDWI, dims=dim, $
                /check, o_min=0, o_max=255, $
                out_name=directory+'\NDWI'+'\'+fname+'NDWI', r_fid=r_fid& catch,errorstatus
              
              
              if errorstatus ne 0 then begin
                 print,'errorstatus',errorstatus
                 print,'errorstatus',error_state.msg
              endif
              
              
              ;; Texture
              pos=[3]
              outbname = ['Variance']
              method = [0,0,1,0,0]
              print,'out_name = ',directory + 'Texture\'+fname+'_Texture'
              
              envi_doit, 'texture_stats_doit', $
                fid=tfid, pos=pos, dims=dim, $
                kx=3, ky=3, method=method, $
                out_name=directory + 'Texture\'+fname+'_Texture', r_fid=r_fid, $
                out_bname=outbname
                
              ;; Brightness  
              pos = lindgen(nb)
              compute_flag = [0,1,0,0,0,0,0,0] ; sum2
              out_dt = 4
              print,'out_name = ',directory + 'Brighness\'+fname+'_sum2'
              
              envi_doit, 'envi_sum_data_doit', $
                fid=tfid, pos=pos, dims=dim, $
                out_name = directory + 'Brighness\'+fname+'_sum2', out_dt=out_dt, $
                compute_flag=compute_flag
                
              envi_file_mng, id=tfid, /remove
      endfor
  
    print,'finished!'
end