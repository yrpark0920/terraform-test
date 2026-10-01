
### basic 디렉토리
- 단순히 테라폼 코드에 적응하기 위해 모듈별로 나누지 않고 작성

### module-test 디렉토리
- basic 디렉토리에서 테라폼 리소스 생성에 대해 익혔으므로 ec2, security-group 등 모듈별로 분리하여 코드 작성
- main.tf에 module 호출하는 부분 정의하고, module-test 내에 ec2, security-group 등 디렉토리별로 분리하여 코드 작성 
