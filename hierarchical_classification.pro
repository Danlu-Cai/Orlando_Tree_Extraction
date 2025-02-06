pro Hierarchical_classification
  ;
  ;   ######################################################################
  ;   # Created on Jan, 2025                                               #
  ;   #                                                                    #
  ;   # Author: Danlu Cai, Department of Atmospheric Science,              #
  ;   #         University of Alabama in Huntsville                        #
  ;   #                                                                    #
  ;   # IDL+ENVI, manipulating hierarchical classification                 #
  ;   #                                                                    #
  ;   ######################################################################
  COMPILE_OPT IDL2
  envi, /restore_base_save_files
  envi_batch_init, log_file='batch.txt'

  directory = DIALOG_PICKFILE(path = "\\uahdata\rgroup\urbanrs\Danlu_data\2024-Orlando_Administrative",/directory)
  fclass = directory+'5_classification\'
  yrs = ["2015","2013","2017","2021","2019"]

  for yr = 1,2-1,1 do begin
    fNDVI = directory+'1_NDVI\'
    fNDWI = directory+'2_NDWI\'
    fTexture = directory+'3_Texture\'
    fBrightness = directory+'4_Brightness\'
    year = yrs[yr]

    tmp = directory+'1_NDVI\'+ year + '\'
    list = findfile(tmp+'*.hdr')
    result = size(list)
    tif_num = result[1]
    print,tif_num
    file_mkdir,fclass + year + '\' +'ENVIClass'
    file_mkdir,fclass + year + '\' +'SieveClass'
    file_mkdir,fclass + year + '\' +'FinalClass'
    file_mkdir,fclass + year + '\' +'CombinedClass'

    for i = 0,tif_num-1,1 do begin ; 137:100
      print,"***********************************",i
      fname = list[i]
      a = STRSPLIT(fname, '\', /EXTRACT)
      tmp = size(a)
      b = STRSPLIT(a[tmp[2]], 'NDVI.hdr', /EXTRACT)
      nameID = b[0]
      OUTID = STRMID(nameID, 0, 12)
      print,'name_ID = ',nameID

      dNDVI = fNDVI + year + '\' + nameID + 'NDVI'
      print,dNDVI
      dNDWI = fNDWI + year + '\' + nameID + 'NDWI'
      print,dNDWI

      envi_open_file, dNDVI, r_fid=fid_NDVI
      envi_open_file, dNDWI, r_fid=fid_NDWI
      envi_file_query, fid_NDVI, dims=dims

      t_fid = [fid_NDWI,fid_NDVI]
      print,'fid = ',t_fid
      pos = [0,0]
      
      if (year eq "2013") Then begin

        exp = "[(b1 gt 0) and (b2 le -0.05)]"
      endif
      
      if (year eq "2015") Then begin

        exp = "[(b1 gt -0.05) and (b2 le 0.05)]"
      endif
      
      if (year eq "2017") Then begin
       
        exp = "[(b1 gt -0.1) and (b2 le 0.15)]"
      endif
      
      if (year eq "2019") Then begin

        exp = "[(b1 gt -0.05) and (b2 le 0.05)]"
      endif
      
      if (year eq "2021") Then begin
        exp = "[(b1 gt 0) and (b2 le 0)]"
      endif
      
      out_name = fclass  +  'tmp_Vege_nonVege'
      print,out_name

      print,"***********************************step1  Vege VS non-Vege ***********************************"
      envi_doit, 'math_doit', $
        fid=t_fid, pos=pos, dims=dims, $
        exp=exp, out_name=out_name, $
        r_fid=r_fid

      map_info = envi_get_map_info(fid = r_fid)
      ENVI_FILE_QUERY, r_fid, dims=dims
      data = ENVI_GET_DATA(fid = r_fid, dims = dims, pos = 0)
      out_class = fclass + year + '\' +'ENVIClass\' + OUTID
      file_type = ENVI_FILE_TYPE('ENVI Classification')

      print,"***********************************step2  ENVI classes ***********************************"
      ENVI_WRITE_ENVI_FILE,data,out_name = out_class,map_info = map_info, $
        NUM_CLASSES=2,CLASS_NAMES=['Vege', "Non-Vege"], LOOKUP=[[0,0,0], [255,255,255]], $
        BNAMES=NameID+"Classification" ,file_type =file_type, R_FID=fid_class

      envi_file_query, fid_class, dims=dimsN, num_classes=num_classes
      posN = [0]

      out_Sieve = fclass + year + '\' +'SieveClass\' + OUTID
      order = bindgen(num_classes)

      print,"***********************************step3  Sieve classes ***********************************"
      envi_doit, 'class_cs_doit', fid=fid_class, /EIGHT, $
        pos=posN, dims=dimsN, order=order, method=1, $
        out_name=out_Sieve, r_fid=fid_Sieve, SIEVE_MIN=8 ,OUT_BNAME = "Sieve_8_8"


      dBrightness = fBrightness + year + '\' + nameID + 'Sum2'
      print,dBrightness
      dTexture = fTexture + year + '\' + nameID + 'TEXTURE'
      print,dTexture


      envi_open_file, dBrightness, r_fid=fid_Brightness
      envi_open_file, dTexture, r_fid=fid_Texture

      envi_file_query, fid_Brightness, dims=dims

      if (year eq "2013") Then begin
        t_fid = [fid_Brightness,fid_Texture,fid_Sieve]
        print,'step4 fid = ',t_fid
        pos = [0,0,0]
        exp = "[(b1 gt 150000) or (b3 eq 1)]*1 + [(b1 lt 50000) or (b2 gt 50)]*2"
      endif
      if (year eq "2015") Then begin
        t_fid = [fid_Brightness,fid_Texture,fid_Sieve]
        print,'step4 fid = ',t_fid
        pos = [0,0,0]
        exp = "[(b1 gt 150000) or (b3 eq 1)]*1 + [(b1 lt 70000) or (b2 gt 50)]*2"
      endif
      if (year eq "2017") Then begin
        f2013 =  fclass + '\2013\SieveClass\' + OUTID
        f2015 =  fclass + '\2015\SieveClass\' + OUTID
        envi_open_file, f2015, r_fid=fid_2013
        envi_open_file, f2015, r_fid=fid_2015
        t_fid = [fid_Brightness,fid_Texture,fid_Sieve,fid_2013,fid_2015,fid_NDVI]
        print,'step4 fid = ',t_fid
        pos = [0,0,0,0,0,0]
        exp = "[(b1 gt 120000) or (b3 eq 1) or (b4 eq 1) or (b5 eq 1) and (b6 lt 0.15)]*1 + [(b1 lt 80000) or (b2 gt 50)]*2"
      endif
      if (year eq "2019") Then begin
        t_fid = [fid_Brightness,fid_Texture,fid_Sieve]
        print,'step4 fid = ',t_fid
        pos = [0,0,0]
        exp = "[(b1 gt 100000) or (b3 eq 1)]*1 + [(b1 lt 55000) or (b2 gt 50)]*2"
      endif
      if (year eq "2021") Then begin
        t_fid = [fid_Brightness,fid_Texture,fid_Sieve]
        print,'step4 fid = ',t_fid
        pos = [0,0,0]
        exp = "[(b1 gt 120000) or (b3 eq 1)]*1 + [(b1 lt 70000) or (b2 gt 50)]*2"
      endif
      Final_name = fclass +  'tmp_Final_classes'
      print,final_name
      print,"***********************************step4  Final classes ***********************************"

      envi_doit, 'math_doit', $
        fid=t_fid, pos=pos, dims=dims, $
        exp=exp, out_name=Final_name, $
        r_fid=r_final


      print,"***********************************step5  Combined classes ***********************************"

      map_info = envi_get_map_info(fid = r_final)

      ENVI_FILE_QUERY, r_final, dims=dims
      data = ENVI_GET_DATA(fid = r_final, dims = dims, pos = 0)

      file_type = ENVI_FILE_TYPE('ENVI Classification')
      out_class = fclass +  'tmp_classes'

      ENVI_WRITE_ENVI_FILE,data,out_name = out_class,map_info = map_info, $
        NUM_CLASSES=4,CLASS_NAMES=['Grass', "Non-Vege","Tree","Non-Vege"], $
        LOOKUP=[[46,139,87], [255,255,255], [139,0,0], [255,255,255]], $
        BNAMES=NameID+"Classification" ,file_type =file_type, R_FID=fid_Final

      ENVI_FILE_QUERY, fid_final, dims=dims, num_classes=num_classes
      pos = [0]
      Combined = fclass + year + '\' +'CombinedClass\' + nameID
      comb_lut = lindgen(num_classes);;"Grass","Non-Vege","Tree","Non-Vege"
      comb_lut[3] = 1


      envi_doit, 'com_class_doit', $
        fid = fid_final, pos=pos, dims=dims, $
        comb_lut=comb_lut, /remove_empty, $
        out_name=Combined, r_fid=r_fid



      envi_file_mng, id=fid_NDVI, /remove
      envi_file_mng, id=fid_NDWI, /remove
      envi_file_mng, id=fid_Brightness, /remove
      envi_file_mng, id=fid_Texture, /remove
      if (year eq "2017") Then begin
         envi_file_mng, id=fid_2013, /remove
         envi_file_mng, id=fid_2015, /remove
      endif
    endfor
    print,"**************** finished! **********************",year
  endfor

end