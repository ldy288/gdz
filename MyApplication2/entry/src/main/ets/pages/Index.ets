// 定义类型接口
interface CellPosition {
  row: number
  col: number
}

@Entry
@Component
struct BlockPuzzleGame {
  // 游戏配置
  @State gridSize: number = 8
  @State cellSize: number = 40
  @State previewCellSize: number = 30

  // 游戏状态
  @State grid: number[][] = []
  @State previewBlock: number[][] = [] // 只有一个预览方块
  @State previewPositionRow: number = -1
  @State previewPositionCol: number = -1

  // 点击预览方块时的偏移量（相对于方块左上角）
  @State clickOffsetRow: number = 0
  @State clickOffsetCol: number = 0

  // 倒计时
  @State countdown: number = 10
  @State isCountdownActive: boolean = false
  private countdownTimer: number = -1

  // 消除动画
  @State clearingCells: CellPosition[] = []
  @State isClearing: boolean = false

  // 分数
  @State score: number = 0

  aboutToAppear() {
    this.initGame()
  }

  aboutToDisappear() {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer)
    }
  }

  // 初始化游戏
  initGame() {
    // 初始化网格
    this.grid = []
    for (let i = 0; i < this.gridSize; i++) {
      let row: number[] = []
      for (let j = 0; j < this.gridSize; j++) {
        row.push(0)
      }
      this.grid.push(row)
    }

    // 生成预览方块
    this.generatePreviewBlock()

    // 启动倒计时
    this.startCountdown()
  }

  // 生成预览方块（只生成一个）
  generatePreviewBlock() {
    // L形
    let block1: number[][] = [[1, 0], [1, 0], [1, 1]]
    // 反L形
    let block2: number[][] = [[0, 1], [0, 1], [1, 1]]
    // T形
    let block3: number[][] = [[1, 1, 1], [0, 1, 0]]
    // 正方形
    let block4: number[][] = [[1, 1], [1, 1]]
    // 长条
    let block5: number[][] = [[1], [1], [1], [1]]
    // Z形
    let block6: number[][] = [[1, 1, 0], [0, 1, 1]]
    // 反Z形
    let block7: number[][] = [[0, 1, 1], [1, 1, 0]]
    // 小L
    let block8: number[][] = [[1, 0], [1, 1]]
    // 单个
    let block9: number[][] = [[1]]
    // 横条
    let block10: number[][] = [[1, 1, 1]]

    let allBlocks: number[][][] = [block1, block2, block3, block4, block5,
      block6, block7, block8, block9, block10]

    // 随机选择1个方块
    let randomIndex = Math.floor(Math.random() * allBlocks.length)
    let block = allBlocks[randomIndex]
    // 深拷贝
    let newBlock: number[][] = []
    for (let r = 0; r < block.length; r++) {
      let newRow: number[] = []
      for (let c = 0; c < block[r].length; c++) {
        newRow.push(block[r][c])
      }
      newBlock.push(newRow)
    }
    this.previewBlock = newBlock
  }

  // 旋转方块
  rotateBlock() {
    if (this.previewBlock.length === 0) return

    let block = this.previewBlock
    let rows = block.length
    let cols = block[0].length

    // 顺时针旋转90度
    let rotated: number[][] = []
    for (let j = 0; j < cols; j++) {
      let newRow: number[] = []
      for (let i = rows - 1; i >= 0; i--) {
        newRow.push(block[i][j])
      }
      rotated.push(newRow)
    }

    this.previewBlock = rotated
  }

  // 启动倒计时
  startCountdown() {
    this.countdown = 10
    this.isCountdownActive = true

    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer)
    }

    this.countdownTimer = setInterval(() => {
      if (this.countdown > 0) {
        this.countdown--
      } else {
        // 倒计时结束，随机放置方块
        this.autoPlaceBlock()
        this.countdown = 10
      }
    }, 1000)
  }

  // 自动放置方块
  autoPlaceBlock() {
    if (this.previewBlock.length === 0) {
      this.generatePreviewBlock()
      return
    }

    let block = this.previewBlock

    // 寻找可放置的位置
    for (let row = 0; row < this.gridSize; row++) {
      for (let col = 0; col < this.gridSize; col++) {
        if (this.canPlaceBlock(block, row, col)) {
          this.placeBlockAt(block, row, col)
          this.generatePreviewBlock()
          this.checkAndClear()
          return
        }
      }
    }

    // 无法放置，重新生成
    this.generatePreviewBlock()
  }

  // 检查是否可以放置
  canPlaceBlock(block: number[][], startRow: number, startCol: number): boolean {
    for (let i = 0; i < block.length; i++) {
      for (let j = 0; j < block[i].length; j++) {
        if (block[i][j] === 1) {
          let row = startRow + i
          let col = startCol + j

          if (row >= this.gridSize || col >= this.gridSize) return false
          if (row < 0 || col < 0) return false
          if (this.grid[row][col] === 1) return false
        }
      }
    }
    return true
  }

  // 深拷贝网格
  copyGrid(): number[][] {
    let newGrid: number[][] = []
    for (let i = 0; i < this.gridSize; i++) {
      let newRow: number[] = []
      for (let j = 0; j < this.gridSize; j++) {
        newRow.push(this.grid[i][j])
      }
      newGrid.push(newRow)
    }
    return newGrid
  }

  // 放置方块
  placeBlockAt(block: number[][], startRow: number, startCol: number) {
    let newGrid = this.copyGrid()

    for (let i = 0; i < block.length; i++) {
      for (let j = 0; j < block[i].length; j++) {
        if (block[i][j] === 1) {
          newGrid[startRow + i][startCol + j] = 1
        }
      }
    }

    this.grid = newGrid
  }

  // 检查并消除
  checkAndClear() {
    let cellsToClear: CellPosition[] = []

    // 检查所有可能的4x4区域
    for (let startRow = 0; startRow <= this.gridSize - 4; startRow++) {
      for (let startCol = 0; startCol <= this.gridSize - 4; startCol++) {
        let isFull = true

        for (let i = 0; i < 4; i++) {
          for (let j = 0; j < 4; j++) {
            if (this.grid[startRow + i][startCol + j] !== 1) {
              isFull = false
              break
            }
          }
          if (!isFull) break
        }

        if (isFull) {
          for (let i = 0; i < 4; i++) {
            for (let j = 0; j < 4; j++) {
              let pos: CellPosition = { row: startRow + i, col: startCol + j }
              cellsToClear.push(pos)
            }
          }
        }
      }
    }

    if (cellsToClear.length > 0) {
      this.clearingCells = cellsToClear
      this.isClearing = true

      // 延迟清除
      setTimeout(() => {
        let newGrid = this.copyGrid()

        // 清除格子
        for (let k = 0; k < this.clearingCells.length; k++) {
          let cell = this.clearingCells[k]
          newGrid[cell.row][cell.col] = 0
        }

        this.grid = newGrid
        this.score += this.clearingCells.length
        this.clearingCells = []
        this.isClearing = false
      }, 1500)
    }
  }

  // 点击预览方块的某个格子
  onPreviewBlockClick(blockRow: number, blockCol: number) {
    if (this.isClearing) return
    // 只有点击了方块的实心格子才有效
    if (this.previewBlock[blockRow][blockCol] !== 1) return

    // 记录点击的偏移量
    this.clickOffsetRow = blockRow
    this.clickOffsetCol = blockCol
    this.previewPositionRow = -1
    this.previewPositionCol = -1
  }

  // 点击放置区域
  onGridClick(row: number, col: number) {
    if (this.isClearing) return
    if (this.previewBlock.length === 0) return

    // 计算方块的放置位置（以点击位置为基准点）
    let startRow = row - this.clickOffsetRow
    let startCol = col - this.clickOffsetCol

    // 检查是否可以放置
    if (!this.canPlaceBlock(this.previewBlock, startRow, startCol)) {
      return // 不能放置，不做任何操作
    }

    // 检查是否点击的是当前预览位置
    if (row === this.previewPositionRow && col === this.previewPositionCol) {
      // 第二次点击同一位置，确认放置
      // 清除预览（灰色）
      this.clearPreview()
      // 放置方块（蓝色）
      this.placeBlockAt(this.previewBlock, startRow, startCol)
      this.previewPositionRow = -1
      this.previewPositionCol = -1

      // 重置倒计时
      this.countdown = 10

      // 检查消除
      this.checkAndClear()

      // 生成新的预览方块
      this.generatePreviewBlock()
    } else {
      // 第一次点击或点击不同位置，显示灰色预览
      // 先清除之前的预览
      this.clearPreview()
      // 设置新的预览位置
      this.previewPositionRow = row
      this.previewPositionCol = col
      // 显示灰色预览
      this.showPreview(this.previewBlock, startRow, startCol)
    }
  }

  // 显示预览
  showPreview(block: number[][], startRow: number, startCol: number) {
    let newGrid = this.copyGrid()

    for (let i = 0; i < block.length; i++) {
      for (let j = 0; j < block[i].length; j++) {
        if (block[i][j] === 1) {
          let r = startRow + i
          let c = startCol + j
          if (r >= 0 && r < this.gridSize && c >= 0 && c < this.gridSize) {
            newGrid[r][c] = 2
          }
        }
      }
    }

    this.grid = newGrid
  }

  // 清除预览
  clearPreview() {
    let newGrid = this.copyGrid()
    let hasPreview = false

    for (let i = 0; i < this.gridSize; i++) {
      for (let j = 0; j < this.gridSize; j++) {
        if (newGrid[i][j] === 2) {
          newGrid[i][j] = 0
          hasPreview = true
        }
      }
    }

    if (hasPreview) {
      this.grid = newGrid
    }
  }

  // 扩展网格
  expandGrid() {
    this.gridSize++
    let newGrid: number[][] = []
    for (let i = 0; i < this.gridSize; i++) {
      let newRow: number[] = []
      for (let j = 0; j < this.gridSize; j++) {
        if (i < this.gridSize - 1 && j < this.gridSize - 1 && this.grid.length > i) {
          newRow.push(this.grid[i][j] || 0)
        } else {
          newRow.push(0)
        }
      }
      newGrid.push(newRow)
    }
    this.grid = newGrid
  }

  // 获取单元格颜色
  getCellColor(row: number, col: number): string {
    // 检查是否在消除动画中
    if (this.isClearing) {
      for (let k = 0; k < this.clearingCells.length; k++) {
        let cell = this.clearingCells[k]
        if (cell.row === row && cell.col === col) {
          return '#FFD700' // 金色消除动画
        }
      }
    }

    let value = this.grid[row][col]
    if (value === 1) {
      return '#2196F3' // 蓝色 - 已放置
    } else if (value === 2) {
      return '#9E9E9E' // 灰色 - 预览
    } else {
      return '#FFFFFF' // 白色 - 空
    }
  }

  build() {
    Column() {
      // 标题和分数
      Row() {
        Text('拼图消除')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Blank()

        Text('分数: ' + this.score)
          .fontSize(18)
          .fontColor('#FF6B6B')
      }
      .width('90%')
      .margin({ top: 20, bottom: 10 })

      // 倒计时
      Row() {
        Text('倒计时: ' + this.countdown + 's')
          .fontSize(20)
          .fontColor(this.countdown <= 3 ? '#FF0000' : '#333333')
          .fontWeight(FontWeight.Bold)
      }
      .width('90%')
      .margin({ bottom: 10 })

      // 放置区域
      Column() {
        ForEach(Array.from({ length: this.gridSize }), (_: ESObject, rowIndex: number) => {
          Row() {
            ForEach(Array.from({ length: this.gridSize }), (_: ESObject, colIndex: number) => {
              Column() {
                Text('')
              }
              .width(this.cellSize)
              .height(this.cellSize)
              .backgroundColor(this.getCellColor(rowIndex, colIndex))
              .border({ width: 1, color: '#CCCCCC' })
              .onClick(() => {
                this.onGridClick(rowIndex, colIndex)
              })
            })
          }
        })
      }
      .padding(5)
      .backgroundColor('#F5F5F5')
      .borderRadius(10)

      Blank().height(20)

      // 扩展按钮
      Row() {
        Button('扩展网格')
          .fontSize(14)
          .onClick(() => this.expandGrid())
          .backgroundColor('#4CAF50')

        Text('当前: ' + this.gridSize + 'x' + this.gridSize)
          .fontSize(14)
          .margin({ left: 10 })
      }
      .width('90%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 10 })

      // 预览区域标题
      Text('预览区域（点击方块格子，再点击放置区域）')
        .fontSize(16)
        .margin({ bottom: 10 })

      // 预览区域（只显示一个方块）
      Column() {
        ForEach(this.previewBlock, (row: number[], rowIndex: number) => {
          Row() {
            ForEach(row, (cell: number, colIndex: number) => {
              Column() {
                Text('')
              }
              .width(this.previewCellSize)
              .height(this.previewCellSize)
              .backgroundColor(cell === 1 ? '#64B5F6' : '#FFFFFF')
              .border({ width: 1, color: '#CCCCCC' })
              .onClick(() => {
                this.onPreviewBlockClick(rowIndex, colIndex)
              })
            })
          }
        })
      }
      .padding(5)
      .backgroundColor('#F5F5F5')
      .borderRadius(5)
      .border({ width: 2, color: '#2196F3' })

      Blank().height(10)

      // 旋转按钮
      Button('旋转方块')
        .fontSize(14)
        .onClick(() => this.rotateBlock())
        .backgroundColor('#FF9800')

      Blank().height(20)

      // 重新开始按钮
      Button('重新开始')
        .fontSize(18)
        .width('50%')
        .onClick(() => {
          if (this.countdownTimer !== -1) {
            clearInterval(this.countdownTimer)
          }
          this.score = 0
          this.previewPositionRow = -1
          this.previewPositionCol = -1
          this.clearingCells = []
          this.isClearing = false
          this.gridSize = 8
          this.initGame()
        })
        .backgroundColor('#FF6B6B')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
