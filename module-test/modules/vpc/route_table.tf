## 라우팅 테이블 생성
## 변수 생성
locals {
    rt_temp = [
        for k,v in local.subnet_information : {
            project_code = split("_", k)[0]
            group = strcontains(v.name, "pub") ? "pub" : strcontains(v.name, "pri") ? "pri" : strcontains(v.name, "eks") ? "eks" : strcontains(v.name, "db") ? "db" : "other"
            az = v.az 
            target_subnet = aws_subnet.this[k]
            target_subnet_id = aws_subnet.this[k]
        }
    ]

    rt_information = {
        for item in local.rt_temp : "${item.project_code}_${item.group}_rt_${item.az}" => item
    }
}