SELECT f_line
		FROM 
	EXTERNAL (
		(
			f_line VARCHAR2(20)
		)
		TYPE oracle_loader
		DEFAULT DIRECTORY ext_data
		ACCESS PARAMETERS 
        (
			RECORDS DELIMITED BY NEWLINE
			BADFILE ext_data
			DISCARDFILE ext_data
            LOGFILE ext_data
			FIELDS
            MISSING FIELD VALUES ARE NULL
			(
				f_line char(20)		
			)
	)
	LOCATION ('files.dat')
	REJECT LIMIT UNLIMITED
	);
--
select * from external (
    (line varchar2(10))
    type oracle_loader
    default directory ext_data
    access parameters (
        records delimited by newline
        nologfile nobadfile nodiscardfile
        fields(line char(10))
    )
    location('files.dat')
    reject limit unlimited
);