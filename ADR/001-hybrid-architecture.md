# ADR 001: Use Hybrid (Local-First + Cloud Sync) Architecture

**Status:** Accepted

**Date:** 2026-02-11

**Context:**

When building Second Brain, we needed to choose between three architectural approaches:

1. **Pure Local**: All data stored locally with no cloud integration
2. **Pure Cloud**: All data stored in the cloud, requiring constant internet connection
3. **Hybrid (Local-First + Cloud Sync)**: Local storage with optional cloud synchronization

Key considerations:
- User experience and app responsiveness
- Offline capability requirements
- Cross-device synchronization needs
- Privacy and data ownership concerns
- Demonstration of technical skills
- Scalability and future features (RAG, embeddings)

**Decision:**

We will implement a **Hybrid (Local-First + Cloud Sync)** architecture using:
- **Isar DB** for local storage (fast, NoSQL, embedded database)
- **Supabase** with **pgvector** for optional cloud sync and vector embeddings

**Rationale:**

1. **Best User Experience**
   - Instant app response with local data access
   - No loading spinners for basic operations
   - Works perfectly offline

2. **Optional Cloud Sync**
   - Users can enable sync for cross-device access
   - Privacy-focused: users control their data
   - Graceful degradation when offline

3. **Technical Excellence**
   - Demonstrates proficiency with both local and cloud databases
   - Showcases sync conflict resolution skills
   - Enables advanced features (pgvector for semantic search)

4. **Future-Proof**
   - Scalable for RAG features (embeddings need vector DB)
   - Supports collaborative features in future
   - Easy to add cloud-only features later

**Consequences:**

### Positive
- ✅ Superior user experience with instant local operations
- ✅ Works offline by default
- ✅ Demonstrates advanced technical skills
- ✅ Enables semantic search with vector embeddings
- ✅ Users maintain data ownership

### Negative
- ❌ Increased complexity in implementation
- ❌ Need to handle sync conflicts
- ❌ More testing scenarios (online/offline states)
- ❌ Requires maintaining two database schemas

### Mitigation
- Use proven sync patterns (CRDTs or timestamp-based)
- Implement comprehensive error handling
- Create thorough test coverage for sync scenarios
- Document sync behavior clearly for users

**Alternatives Considered:**

1. **Pure Local** — Simpler but no cross-device sync
2. **Pure Cloud** — Poor offline experience, slower operations
3. **Firebase** — Considered but Supabase chosen for pgvector support

**Related Decisions:**
- Technology choice: Isar DB for local storage
- Technology choice: Supabase + pgvector for cloud
- Will require: Sync strategy ADR in future (Phase 4)
