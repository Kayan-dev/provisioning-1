# we are extending everything from tomcat:8.0 image ...
FROM tomcat:9.0

LABEL key="Efe" 

# COPY path-to-your-application-war path-to-webapps-in-docker-tomcat
COPY ./target/petclinic.war /usr/local/tomcat/webapps/

# ADD target/petclinic.war *.war
# ENTRYPOINT ["-war", "petclinic.war"]
