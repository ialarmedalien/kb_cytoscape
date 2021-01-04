function getData() {
  return {
    nodes: [
      {
        id: "d",
        name: 'fee',
      },
      {
        id: "c",
        name: 'fie',
      },
      {
        id: "b",
        name: 'foe',
      },
      {
        id: "a",
        name: 'fum',
      }
    ],
    edges: [
      {
        id: "a_b",
        source: "a",
        target: "b",
      },
      {
        id: "a_d",
        source: "a",
        target: "d",
      },
      {
        id: "c_d",
        source: "c",
        target: "d",
      },
    ],
  }
}

export default getData
