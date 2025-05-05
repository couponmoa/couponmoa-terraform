# 🛠️ couponmoa-terraform
---
## 📌 개요

이 레포지토리는 **Couponmoa 프로젝트의 AWS 인프라를 Terraform으로 관리**하기 위한 코드 저장소입니다.  
VPC부터 ECS, RDS, SQS, CloudFront 등 MSA 아키텍처에 필요한 리소스를 코드로 관리하고 배포합니다.

---

## ⚙️ 주요 기능
- VPC, 서브넷, NAT, IGW 등 네트워크 구성
- ECS Cluster 및 Fargate 기반 서비스 배포
- 서비스 디스커버리를 위한 Cloud Map
- S3, CloudFront 정적 자원 배포 설정
- Elasticsearch (EC2), RDS, ElastiCache 구성
- SQS를 이용한 비동기 메시징

---

```
처음 .idea 폴더 안에서 실수로 커밋해서 GitHub가 언어를 잘못 인식하고
폴더 구조를 바꿔도 초기 커밋 기준으로 표시되었습니다.
이는 코드의 실질적인 언어와 무관하며, 실제 프로젝트는 Terraform 기반의 IaC 구성 레포지토리입니다.
```
