# Public Assets

这个文件夹用于存放**静态资源**，这些资源会被直接提供给浏览器，不经过webpack处理。

## 文件夹结构

- `images/` - 存放静态图片文件
- `icons/` - 存放图标文件

## 使用方式

在React组件中，可以通过以下方式引用：

```jsx
// 使用 process.env.PUBLIC_URL 获取public文件夹的路径
<img src={`${process.env.PUBLIC_URL}/assets/images/pokemon-logo.png`} alt="Logo" />

// 或者直接使用相对路径（推荐）
<img src="/assets/images/pokemon-logo.png" alt="Logo" />
```

## 适用场景

- 网站Logo
- Favicon
- 静态背景图片
- 不需要优化的大图片
- 需要在HTML中直接引用的资源