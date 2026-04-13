package utils

import (
	"errors"
	"fmt"
	"reflect"
	"strings"

	"github.com/go-playground/locales/zh"
	ut "github.com/go-playground/universal-translator"
	"github.com/go-playground/validator/v10"
	zhTrans "github.com/go-playground/validator/v10/translations/zh"
)

var (
	validate *validator.Validate
	trans    ut.Translator
)

func init() {
	validate = validator.New()
	zhLocale := zh.New()
	uni := ut.New(zhLocale, zhLocale)
	trans, _ = uni.GetTranslator("zh")
	_ = zhTrans.RegisterDefaultTranslations(validate, trans)

	validate.RegisterTagNameFunc(func(field reflect.StructField) string {
		label := field.Tag.Get("label")
		if label == "" {
			return field.Name
		}
		return label
	})
}

func TranslateBindingError(err error, obj interface{}) string {
	var ve validator.ValidationErrors
	if errors.As(err, &ve) {
		var errMsgs []string
		for _, e := range ve {
			field := e.Field()
			tag := e.Tag()
			switch tag {
			case "required":
				errMsgs = append(errMsgs, fmt.Sprintf("%s不能为空", field))
			case "min":
				errMsgs = append(errMsgs, fmt.Sprintf("%s长度不能少于%s", field, e.Param()))
			case "max":
				errMsgs = append(errMsgs, fmt.Sprintf("%s长度不能超过%s", field, e.Param()))
			default:
				errMsgs = append(errMsgs, fmt.Sprintf("%s格式错误", field))
			}
		}
		return strings.Join(errMsgs, "；")
	}
	return "参数格式错误"
}
