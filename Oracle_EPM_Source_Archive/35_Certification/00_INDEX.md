# 35. Certification — Oracle Certified Implementation Specialist Playbook

> **Consultant High-Yield Summary:**  
> Passing the Oracle Cloud EPM Planning Implementation Specialist (1Z0-1080) exam validates end-to-end expertise across design, configuration, security, data integration, and automation. This playbook provides targeted exam strategies, core domain weightings, and practice questions.

---

## ðŸŽ¯ Live Interactive Visual Architecture Card

<details open>
<summary><b>ðŸŽ¯ Live Interactive Architecture Card: Oracle EPM Planning Specialist Exam Blueprint (1Z0-1080)</b></summary>

| Exam Domain | Topic Weighting | High-Frequency Question Concepts |
| :--- | :--- | :--- |
| **Application Creation & Config** | 25% | Multi-currency setup, Calendar creation, Hybrid BSO enablement, Enable Features. |
| **Dimensions & Metadata** | 20% | Account Types, Time Balance settings, Implied Share rules, Data Storage properties. |
| **Forms & Dashboards** | 15% | Suppress missing, validation rules, Action Menus, Smart Push attachment. |
| **Calculations & Business Rules** | 20% | Scoping with FIX, Runtime Prompts, Calc Manager templates, Groovy event triggers. |
| **Data Integration & Security** | 20% | Import Formats, Mapping types, CLS precedence, Predefined roles, EPM Automate CLI. |

```mermaid
flowchart LR
    D1["Domain 1: Setup & Config<br/>(25%)"] --> D2["Domain 2: Metadata<br/>(20%)"]
    D2 --> D3["Domain 3: Forms & UI<br/>(15%)"]
    D3 --> D4["Domain 4: Rules & Calcs<br/>(20%)"]
    D4 --> D5["Domain 5: Integration & Security<br/>(20%)"]
    D5 --> Pass["1Z0-1080 Exam Success<br/>Certified Specialist"]
```

</details>

---

## ðŸ›ï¸ Architectural Comparison & Design Patterns

| Exam Question Style | Straightforward Knowledge Question | Scenario-Based Exam Trap |
| :--- | :--- | :--- |
| Question Type | 'Which predefined role can create forms?' | 'A user in Group A (Write) and Group B (None) sees #NoAccess. Why?' |
| Evaluation Focus | Memorized definitions and role permissions | Understanding least-privilege collision rules and real-world behavior |
| Preparation Strategy | Read official product documentation | Hands-on instance practice building forms, rules, and security combinations |

---

## ðŸ’¼ Tough & Twisted Review Scenarios (Consultant Review Defense)

### Question 1: "On the certification exam, a question asks: 'Which two dimensions must be created before any other dimensions can be loaded?' What is the correct answer?"
> **Consultant Model Answer:**  
> Period and Years. In Oracle Cloud EPM Planning, the calendar framework (Period and Years) defines the base time horizon of the application. All time-series calculations, dynamic rolling periods, and scenario configurations depend directly on the time dimension definitions.

---

## ðŸ“‘ Complete Document Catalog

| # | Document File | Topic Description |
|---|---------------|-------------------|
| 01 | [27.01_Exam_1Z0_1086_Complete_Guide.md](./27.01_Exam_1Z0_1086_Complete_Guide.md) | 27.01 â€” Oracle EPM Cloud Certification Exam Guide (1Z0-1086) |
| 02 | [README.md](./README.md) | 24 Certification â€” Oracle EPM Cloud Certification Prep |

---

> **Consultant Implementation Note:** Master the architectural comparison and review defense questions in this module before presenting designs to client stakeholders or senior review panels.