package main

import (
	"log"
	"shiguangji/config"
	"shiguangji/router"
	"shiguangji/service"
)

func main() {
	config.GetSettings()

	err := service.InitServices()
	if err != nil {
		log.Println("注册服务失败")
		return
	}
	r := router.InitRouter()

	r.Run("0.0.0.0:9000")
}
